# Phase 4.1: Price Display

## Feature Overview

Display current market prices for cards throughout the application. This feature provides collectors with pricing information to understand the value of individual cards and make informed decisions about their collection.

**Priority**: Medium (valuable for understanding collection worth)
**Dependencies**: Phase 1.3 (Card Detail View), Phase 2.3 (Item Detail)
**Estimated Complexity**: Medium-High

---

## Background: MTGJSON Pricing Data

### Data Source

MTGJSON provides pricing data through separate JSON files (not included in the SQLite database):
- **AllPricesToday.json**: Current day pricing (~50MB)
- **AllPrices.json**: 90-day historical pricing (~500MB)

### Price Structure

Prices are organized by card UUID with the following hierarchy:

```
{
  "uuid": {
    "paper": {
      "tcgplayer": {
        "currency": "USD",
        "retail": {
          "normal": { "2024-01-15": 2.50, "2024-01-14": 2.45 },
          "foil": { "2024-01-15": 8.00, "2024-01-14": 7.95 }
        },
        "buylist": {
          "normal": { "2024-01-15": 1.50 },
          "foil": { "2024-01-15": 5.00 }
        }
      },
      "cardmarket": {
        "currency": "EUR",
        "retail": { ... },
        "buylist": { ... }
      },
      "cardkingdom": { ... },
      "cardsphere": { ... }
    },
    "mtgo": {
      "cardhoarder": { ... }
    }
  }
}
```

### Price Providers

| Provider | Currency | Market | Notes |
|----------|----------|--------|-------|
| TCGPlayer | USD | US | Primary US market |
| CardMarket | EUR | EU | Primary EU market |
| Card Kingdom | USD | US | Major retailer |
| Cardsphere | USD | US | Trading platform |
| Card Hoarder | USD | MTGO | Digital only |

### Implementation Approach

Since pricing data is not in the SQLite database, this feature requires:
1. A local pricing cache (SQLite table in primary database)
2. Rake tasks to download and import pricing data
3. Background job for scheduled updates
4. Graceful handling of missing prices

---

## User Stories

### US-4.1.1: View Price on Card Detail
**As a** collector
**I want to** see the current market price when viewing a card
**So that** I know what the card is worth

### US-4.1.2: View Price on Item Detail
**As a** collector
**I want to** see the price for the specific version I own
**So that** I know what my particular copy is worth

### US-4.1.3: See Foil vs Non-Foil Prices
**As a** collector
**I want to** see different prices for foil and non-foil versions
**So that** I can compare values accurately

### US-4.1.4: View Price Source
**As a** collector
**I want to** know where price data comes from
**So that** I can understand the pricing methodology

### US-4.1.5: See Price Currency
**As a** collector
**I want to** see prices in a consistent currency
**So that** I can understand values without conversion

### US-4.1.6: View Price Freshness
**As a** collector
**I want to** know when prices were last updated
**So that** I can gauge reliability of pricing

### US-4.1.7: Handle Missing Prices
**As a** collector
**I want to** see a clear indication when price is unavailable
**So that** I'm not confused by missing data

### US-4.1.8: View Price in Item List
**As a** collector
**I want to** see prices in item list views
**So that** I can quickly scan collection values

---

## Acceptance Criteria

### AC-4.1.1: Card Detail Price Display

```gherkin
Feature: Price on Card Detail Page

  Scenario: Card with available pricing
    Given I view a card that has pricing data
    Then I should see the current market price
    And I should see both normal and foil prices (if available)
    And I should see the price source (e.g., "TCGPlayer")
    And I should see the currency (e.g., "USD")

  Scenario: Card without pricing
    Given I view a card with no pricing data
    Then I should see "Price unavailable"
    And I should not see a price value

  Scenario: Price display format
    Given I view a card with price $12.50
    Then the price should be displayed as "$12.50"
    And values under $1 should show cents (e.g., "$0.25")
    And values over $1000 should show commas (e.g., "$1,234.56")
```

### AC-4.1.2: Item Detail Price Display

```gherkin
Feature: Price on Item Detail Page

  Scenario: Non-foil item price
    Given I have a non-foil item
    When I view the item detail
    Then I should see the normal (non-foil) price
    And it should reflect the card's set/printing

  Scenario: Foil item price
    Given I have a traditional foil item
    When I view the item detail
    Then I should see the foil price
    And I should see indication this is the foil price

  Scenario: Etched foil item price
    Given I have an etched foil item
    When I view the item detail
    Then I should see the etched price if available
    Or I should see the foil price as fallback
    Or I should see "Price unavailable" if neither exists

  Scenario: Item condition consideration note
    Given I view any item's price
    Then I should see a note like "Price shown is for Near Mint condition"
    And I should understand this is market price, not condition-adjusted
```

### AC-4.1.3: Price Source Attribution

```gherkin
Feature: Price Source Display

  Scenario: Single source available
    Given only TCGPlayer pricing is available
    Then I should see "TCGPlayer" as the source

  Scenario: Price date shown
    Given the price was last updated on "2024-01-15"
    Then I should see "as of Jan 15, 2024" or similar
    Or I should see "Updated today" if current

  Scenario: Stale price warning
    Given pricing data is more than 7 days old
    Then I should see a visual indicator that prices may be stale
    And I should see when prices were last updated
```

### AC-4.1.4: Multiple Price Display

```gherkin
Feature: Multiple Price Points

  Scenario: Show retail and buylist
    Given a card has both retail and buylist prices
    When I view the card detail
    Then I should see "Market: $10.00" (retail)
    And I should optionally see "Buylist: $7.00" (what stores pay)

  Scenario: Primary price emphasis
    Given multiple price sources exist
    Then the retail price should be most prominent
    And buylist should be secondary or expandable
```

### AC-4.1.5: Items List Price Column

```gherkin
Feature: Price in Item Lists

  Scenario: Price column in items index
    Given I view my collection items
    Then I should see a price column
    And each item should show its individual price

  Scenario: Price matches item finish
    Given I have a foil item worth $8.00
    And a non-foil of same card worth $2.00
    Then the foil item should show $8.00
    And the non-foil item should show $2.00

  Scenario: Items without prices
    Given an item has no price data
    Then the price column should show "-" or "N/A"
    And it should not show "$0.00"
```

### AC-4.1.6: Price Caching and Freshness

```gherkin
Feature: Price Data Management

  Scenario: View last update time
    Given I am viewing the application
    Then I should be able to see when prices were last updated
    And this could be on a settings/info page

  Scenario: Missing price data notice
    Given price data has never been imported
    Then relevant views should show a notice
    And the notice should explain how to import prices
```

### AC-4.1.7: Currency Handling

```gherkin
Feature: Currency Display

  Scenario: USD prices
    Given prices are from TCGPlayer (USD)
    Then prices should show "$" symbol
    And values should be formatted for USD

  Scenario: EUR prices (future)
    Given prices are from CardMarket (EUR)
    Then prices should show proper EUR formatting
    Note: MVP focuses on USD/TCGPlayer only
```

---

## Technical Implementation

### Database Schema

```ruby
# db/migrate/XXXXXX_create_card_prices.rb
class CreateCardPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :card_prices do |t|
      t.string :card_uuid, null: false, index: true
      t.string :provider, null: false  # tcgplayer, cardmarket, etc.
      t.string :currency, null: false  # USD, EUR
      t.decimal :retail_normal, precision: 10, scale: 2
      t.decimal :retail_foil, precision: 10, scale: 2
      t.decimal :retail_etched, precision: 10, scale: 2
      t.decimal :buylist_normal, precision: 10, scale: 2
      t.decimal :buylist_foil, precision: 10, scale: 2
      t.decimal :buylist_etched, precision: 10, scale: 2
      t.date :price_date, null: false
      t.datetime :fetched_at, null: false

      t.timestamps
    end

    add_index :card_prices, [:card_uuid, :provider], unique: true
    add_index :card_prices, :price_date
  end
end
```

### Model

```ruby
# app/models/card_price.rb
class CardPrice < ApplicationRecord
  PROVIDERS = %w[tcgplayer cardmarket cardkingdom cardsphere].freeze
  CURRENCIES = %w[USD EUR].freeze
  DEFAULT_PROVIDER = "tcgplayer".freeze

  validates :card_uuid, presence: true
  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :currency, presence: true, inclusion: { in: CURRENCIES }
  validates :price_date, presence: true
  validates :fetched_at, presence: true

  scope :for_card, ->(uuid) { where(card_uuid: uuid) }
  scope :for_provider, ->(provider) { where(provider: provider) }
  scope :latest, -> { order(price_date: :desc).limit(1) }

  def self.default_for(card_uuid)
    for_card(card_uuid).for_provider(DEFAULT_PROVIDER).latest.first
  end

  def price_for_finish(finish)
    case finish.to_s
    when "nonfoil"
      retail_normal
    when "traditional_foil", "glossy", "surge_foil", "textured"
      retail_foil
    when "etched"
      retail_etched || retail_foil  # Fallback to foil if etched not available
    else
      retail_normal
    end
  end

  def has_price?
    retail_normal.present? || retail_foil.present? || retail_etched.present?
  end

  def stale?
    price_date < 7.days.ago.to_date
  end

  def fresh?
    price_date >= 1.day.ago.to_date
  end
end
```

### Service Objects

```ruby
# app/services/price_lookup.rb
class PriceLookup
  def initialize(card_uuid:, finish: :nonfoil, provider: CardPrice::DEFAULT_PROVIDER)
    @card_uuid = card_uuid
    @finish = finish
    @provider = provider
  end

  def call
    price_record = CardPrice.default_for(@card_uuid)
    return NullPrice.new unless price_record

    PriceResult.new(
      amount: price_record.price_for_finish(@finish),
      currency: price_record.currency,
      provider: price_record.provider,
      price_date: price_record.price_date,
      stale: price_record.stale?
    )
  end

  class PriceResult
    attr_reader :amount, :currency, :provider, :price_date, :stale

    def initialize(amount:, currency:, provider:, price_date:, stale:)
      @amount = amount
      @currency = currency
      @provider = provider
      @price_date = price_date
      @stale = stale
    end

    def available?
      amount.present? && amount > 0
    end

    def stale?
      @stale
    end

    def formatted
      return nil unless available?
      format_price(amount, currency)
    end

    private

    def format_price(amount, currency)
      case currency
      when "USD"
        number_to_currency(amount, unit: "$")
      when "EUR"
        number_to_currency(amount, unit: "\u20AC", format: "%n %u")
      else
        number_to_currency(amount)
      end
    end

    def number_to_currency(amount, **options)
      ActionController::Base.helpers.number_to_currency(amount, **options)
    end
  end

  class NullPrice
    def amount = nil
    def currency = nil
    def provider = nil
    def price_date = nil
    def available? = false
    def stale? = true
    def formatted = nil
  end
end
```

```ruby
# app/services/price_import.rb
class PriceImport
  MTGJSON_PRICES_URL = "https://mtgjson.com/api/v5/AllPricesToday.json".freeze

  def initialize(provider: CardPrice::DEFAULT_PROVIDER)
    @provider = provider
  end

  def call
    data = fetch_price_data
    return Result.failure("Failed to fetch price data") unless data

    import_count = 0
    price_date = Date.current

    data.each do |uuid, price_data|
      next unless price_data.dig("paper", @provider)

      provider_data = price_data.dig("paper", @provider)
      currency = provider_data["currency"] || "USD"

      # Get the most recent price for each category
      retail_normal = latest_price(provider_data.dig("retail", "normal"))
      retail_foil = latest_price(provider_data.dig("retail", "foil"))
      retail_etched = latest_price(provider_data.dig("retail", "etched"))
      buylist_normal = latest_price(provider_data.dig("buylist", "normal"))
      buylist_foil = latest_price(provider_data.dig("buylist", "foil"))
      buylist_etched = latest_price(provider_data.dig("buylist", "etched"))

      # Skip if no prices available
      next unless [retail_normal, retail_foil, retail_etched].any?

      CardPrice.upsert(
        {
          card_uuid: uuid,
          provider: @provider,
          currency: currency,
          retail_normal: retail_normal,
          retail_foil: retail_foil,
          retail_etched: retail_etched,
          buylist_normal: buylist_normal,
          buylist_foil: buylist_foil,
          buylist_etched: buylist_etched,
          price_date: price_date,
          fetched_at: Time.current,
          created_at: Time.current,
          updated_at: Time.current
        },
        unique_by: [:card_uuid, :provider]
      )
      import_count += 1
    end

    Result.success(import_count)
  end

  private

  def fetch_price_data
    response = Net::HTTP.get(URI(MTGJSON_PRICES_URL))
    JSON.parse(response)["data"]
  rescue StandardError => e
    Rails.logger.error("Price fetch failed: #{e.message}")
    nil
  end

  def latest_price(price_hash)
    return nil unless price_hash.is_a?(Hash) && price_hash.any?

    # Get the most recent date's price
    latest_date = price_hash.keys.max
    price_hash[latest_date]
  end

  class Result
    attr_reader :count, :error

    def self.success(count) = new(count: count)
    def self.failure(error) = new(error: error)

    def initialize(count: nil, error: nil)
      @count = count
      @error = error
    end

    def success? = error.nil?
    def failure? = !success?
  end
end
```

### Rake Tasks

```ruby
# lib/tasks/prices.rake
namespace :prices do
  desc "Download and import current prices from MTGJSON"
  task import: :environment do
    puts "Importing prices from MTGJSON..."

    result = PriceImport.new.call

    if result.success?
      puts "Successfully imported #{result.count} card prices"
    else
      puts "Import failed: #{result.error}"
      exit 1
    end
  end

  desc "Show price data statistics"
  task info: :environment do
    total = CardPrice.count
    if total.zero?
      puts "No price data imported yet."
      puts "Run: bin/rails prices:import"
    else
      latest = CardPrice.maximum(:price_date)
      puts "Price Data Statistics:"
      puts "  Total records: #{total}"
      puts "  Latest price date: #{latest}"
      puts "  Providers: #{CardPrice.distinct.pluck(:provider).join(', ')}"
    end
  end

  desc "Clear all price data"
  task clear: :environment do
    count = CardPrice.delete_all
    puts "Deleted #{count} price records"
  end
end
```

### Item Model Enhancement

```ruby
# app/models/item.rb (additions)
class Item < ApplicationRecord
  # ... existing code ...

  def price
    @price ||= PriceLookup.new(card_uuid: card_uuid, finish: finish).call
  end

  def price_amount
    price.amount
  end

  def formatted_price
    price.formatted || "N/A"
  end

  def has_price?
    price.available?
  end
end
```

### Helper Methods

```ruby
# app/helpers/prices_helper.rb
module PricesHelper
  def format_price(amount, currency: "USD")
    return "N/A" if amount.nil?
    return "N/A" if amount <= 0

    case currency
    when "USD"
      number_to_currency(amount, unit: "$", precision: 2)
    when "EUR"
      number_to_currency(amount, unit: "\u20AC", precision: 2, format: "%n %u")
    else
      number_to_currency(amount, precision: 2)
    end
  end

  def price_source_badge(provider)
    provider_names = {
      "tcgplayer" => "TCGPlayer",
      "cardmarket" => "CardMarket",
      "cardkingdom" => "Card Kingdom",
      "cardsphere" => "Cardsphere"
    }

    content_tag(:span, provider_names[provider] || provider,
      class: "text-xs text-gray-500")
  end

  def price_freshness_indicator(price_date)
    return unless price_date

    days_old = (Date.current - price_date).to_i

    if days_old <= 1
      content_tag(:span, "Updated today", class: "text-xs text-green-600")
    elsif days_old <= 7
      content_tag(:span, "#{days_old} days ago", class: "text-xs text-gray-500")
    else
      content_tag(:span, "#{days_old} days old", class: "text-xs text-amber-600")
    end
  end

  def price_unavailable_indicator
    content_tag(:span, "Price unavailable", class: "text-sm text-gray-400 italic")
  end
end
```

### Views

```erb
<%# app/views/items/_price_display.html.erb %>
<% price = item.price %>

<div class="price-display">
  <% if price.available? %>
    <span class="text-lg font-semibold text-gray-900">
      <%= price.formatted %>
    </span>

    <div class="flex items-center gap-2 mt-1">
      <%= price_source_badge(price.provider) %>
      <%= price_freshness_indicator(price.price_date) %>
    </div>

    <% if price.stale? %>
      <p class="text-xs text-amber-600 mt-1">
        Prices may be outdated
      </p>
    <% end %>
  <% else %>
    <%= price_unavailable_indicator %>
  <% end %>
</div>
```

```erb
<%# app/views/cards/_price_section.html.erb %>
<section class="bg-white rounded-lg border border-gray-200 p-4">
  <h3 class="text-sm font-medium text-gray-500 mb-3">Market Price</h3>

  <% price_normal = CardPrice.default_for(@card.uuid) %>

  <% if price_normal&.has_price? %>
    <div class="space-y-3">
      <% if price_normal.retail_normal %>
        <div class="flex justify-between items-center">
          <span class="text-gray-600">Non-foil</span>
          <span class="font-semibold"><%= format_price(price_normal.retail_normal) %></span>
        </div>
      <% end %>

      <% if price_normal.retail_foil %>
        <div class="flex justify-between items-center">
          <span class="text-gray-600">Foil</span>
          <span class="font-semibold"><%= format_price(price_normal.retail_foil) %></span>
        </div>
      <% end %>

      <% if price_normal.retail_etched %>
        <div class="flex justify-between items-center">
          <span class="text-gray-600">Etched</span>
          <span class="font-semibold"><%= format_price(price_normal.retail_etched) %></span>
        </div>
      <% end %>

      <div class="pt-2 border-t border-gray-100">
        <div class="flex items-center justify-between text-xs text-gray-500">
          <%= price_source_badge(price_normal.provider) %>
          <%= price_freshness_indicator(price_normal.price_date) %>
        </div>
      </div>
    </div>
  <% else %>
    <div class="text-center py-4">
      <%= price_unavailable_indicator %>
      <p class="text-xs text-gray-400 mt-2">
        Price data not available for this card
      </p>
    </div>
  <% end %>
</section>
```

### Routes

No new routes required for basic price display. Price data is fetched from the local cache and displayed on existing views.

---

## Database Changes

### New Migration

```ruby
# db/migrate/XXXXXX_create_card_prices.rb
class CreateCardPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :card_prices do |t|
      t.string :card_uuid, null: false
      t.string :provider, null: false
      t.string :currency, null: false, default: "USD"
      t.decimal :retail_normal, precision: 10, scale: 2
      t.decimal :retail_foil, precision: 10, scale: 2
      t.decimal :retail_etched, precision: 10, scale: 2
      t.decimal :buylist_normal, precision: 10, scale: 2
      t.decimal :buylist_foil, precision: 10, scale: 2
      t.decimal :buylist_etched, precision: 10, scale: 2
      t.date :price_date, null: false
      t.datetime :fetched_at, null: false

      t.timestamps
    end

    add_index :card_prices, [:card_uuid, :provider], unique: true
    add_index :card_prices, :card_uuid
    add_index :card_prices, :price_date
    add_index :card_prices, :provider
  end
end
```

---

## Test Requirements

### Model Specs

```ruby
# spec/models/card_price_spec.rb
require "rails_helper"

RSpec.describe CardPrice, type: :model do
  describe "validations" do
    it { should validate_presence_of(:card_uuid) }
    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:price_date) }
    it { should validate_presence_of(:fetched_at) }

    it "validates provider is in allowed list" do
      price = build(:card_price, provider: "invalid")
      expect(price).not_to be_valid
      expect(price.errors[:provider]).to include(match(/not included/))
    end
  end

  describe "scopes" do
    let!(:tcg_price) { create(:card_price, provider: "tcgplayer") }
    let!(:cm_price) { create(:card_price, provider: "cardmarket") }

    describe ".for_provider" do
      it "filters by provider" do
        expect(CardPrice.for_provider("tcgplayer")).to include(tcg_price)
        expect(CardPrice.for_provider("tcgplayer")).not_to include(cm_price)
      end
    end

    describe ".for_card" do
      let!(:other_price) { create(:card_price, card_uuid: "different-uuid") }

      it "filters by card UUID" do
        expect(CardPrice.for_card(tcg_price.card_uuid)).to include(tcg_price)
        expect(CardPrice.for_card(tcg_price.card_uuid)).not_to include(other_price)
      end
    end
  end

  describe "#price_for_finish" do
    let(:price) do
      create(:card_price,
        retail_normal: 5.00,
        retail_foil: 15.00,
        retail_etched: 12.00
      )
    end

    it "returns normal price for nonfoil" do
      expect(price.price_for_finish(:nonfoil)).to eq(5.00)
    end

    it "returns foil price for traditional_foil" do
      expect(price.price_for_finish(:traditional_foil)).to eq(15.00)
    end

    it "returns etched price for etched" do
      expect(price.price_for_finish(:etched)).to eq(12.00)
    end

    it "falls back to foil for etched when etched unavailable" do
      price.update!(retail_etched: nil)
      expect(price.price_for_finish(:etched)).to eq(15.00)
    end
  end

  describe "#stale?" do
    it "returns true when price_date is more than 7 days old" do
      price = create(:card_price, price_date: 8.days.ago)
      expect(price.stale?).to be true
    end

    it "returns false when price_date is recent" do
      price = create(:card_price, price_date: Date.current)
      expect(price.stale?).to be false
    end
  end

  describe ".default_for" do
    let(:uuid) { "test-uuid-123" }

    it "returns the latest tcgplayer price for a card" do
      old_price = create(:card_price, card_uuid: uuid, provider: "tcgplayer", price_date: 2.days.ago)
      new_price = create(:card_price, card_uuid: uuid, provider: "tcgplayer", price_date: Date.current)

      expect(CardPrice.default_for(uuid)).to eq(new_price)
    end

    it "returns nil when no price exists" do
      expect(CardPrice.default_for("nonexistent")).to be_nil
    end
  end
end
```

### Service Specs

```ruby
# spec/services/price_lookup_spec.rb
require "rails_helper"

RSpec.describe PriceLookup do
  let(:card_uuid) { "test-uuid-123" }

  describe "#call" do
    context "when price exists" do
      let!(:price) do
        create(:card_price,
          card_uuid: card_uuid,
          provider: "tcgplayer",
          retail_normal: 5.00,
          retail_foil: 15.00,
          currency: "USD",
          price_date: Date.current
        )
      end

      it "returns price for nonfoil" do
        result = PriceLookup.new(card_uuid: card_uuid, finish: :nonfoil).call
        expect(result.amount).to eq(5.00)
        expect(result.available?).to be true
      end

      it "returns price for foil" do
        result = PriceLookup.new(card_uuid: card_uuid, finish: :traditional_foil).call
        expect(result.amount).to eq(15.00)
      end

      it "includes provider and currency" do
        result = PriceLookup.new(card_uuid: card_uuid).call
        expect(result.provider).to eq("tcgplayer")
        expect(result.currency).to eq("USD")
      end

      it "formats price correctly" do
        result = PriceLookup.new(card_uuid: card_uuid).call
        expect(result.formatted).to eq("$5.00")
      end
    end

    context "when price does not exist" do
      it "returns null price object" do
        result = PriceLookup.new(card_uuid: "nonexistent").call
        expect(result.available?).to be false
        expect(result.formatted).to be_nil
      end
    end

    context "when price is stale" do
      let!(:price) do
        create(:card_price, card_uuid: card_uuid, price_date: 10.days.ago)
      end

      it "indicates staleness" do
        result = PriceLookup.new(card_uuid: card_uuid).call
        expect(result.stale?).to be true
      end
    end
  end
end
```

```ruby
# spec/services/price_import_spec.rb
require "rails_helper"

RSpec.describe PriceImport do
  describe "#call" do
    let(:sample_data) do
      {
        "data" => {
          "uuid-1" => {
            "paper" => {
              "tcgplayer" => {
                "currency" => "USD",
                "retail" => {
                  "normal" => { "2024-01-15" => 5.00, "2024-01-14" => 4.95 },
                  "foil" => { "2024-01-15" => 15.00 }
                }
              }
            }
          },
          "uuid-2" => {
            "paper" => {
              "tcgplayer" => {
                "currency" => "USD",
                "retail" => {
                  "normal" => { "2024-01-15" => 2.50 }
                }
              }
            }
          }
        }
      }
    end

    before do
      stub_request(:get, PriceImport::MTGJSON_PRICES_URL)
        .to_return(status: 200, body: sample_data.to_json)
    end

    it "imports prices successfully" do
      result = described_class.new.call
      expect(result.success?).to be true
      expect(result.count).to eq(2)
    end

    it "creates CardPrice records" do
      expect { described_class.new.call }.to change(CardPrice, :count).by(2)
    end

    it "imports correct price values" do
      described_class.new.call

      price = CardPrice.find_by(card_uuid: "uuid-1")
      expect(price.retail_normal).to eq(5.00)
      expect(price.retail_foil).to eq(15.00)
    end

    it "uses the most recent date's price" do
      described_class.new.call

      price = CardPrice.find_by(card_uuid: "uuid-1")
      expect(price.retail_normal).to eq(5.00)  # From 2024-01-15, not 2024-01-14
    end

    context "when fetch fails" do
      before do
        stub_request(:get, PriceImport::MTGJSON_PRICES_URL)
          .to_return(status: 500)
      end

      it "returns failure result" do
        result = described_class.new.call
        expect(result.failure?).to be true
      end
    end

    context "when updating existing prices" do
      let!(:existing) { create(:card_price, card_uuid: "uuid-1", retail_normal: 3.00) }

      it "updates existing records" do
        expect { described_class.new.call }.not_to change(CardPrice, :count)

        existing.reload
        expect(existing.retail_normal).to eq(5.00)
      end
    end
  end
end
```

### Item Price Specs

```ruby
# spec/models/item_spec.rb (additions)
RSpec.describe Item, type: :model do
  describe "#price" do
    let(:item) { create(:item, card_uuid: "test-uuid", finish: :nonfoil) }

    context "with price data" do
      before do
        create(:card_price,
          card_uuid: "test-uuid",
          retail_normal: 10.00,
          retail_foil: 25.00
        )
      end

      it "returns price lookup result" do
        expect(item.price.amount).to eq(10.00)
      end

      it "returns formatted price" do
        expect(item.formatted_price).to eq("$10.00")
      end

      it "matches finish to price type" do
        foil_item = create(:item, card_uuid: "test-uuid", finish: :traditional_foil)
        expect(foil_item.price.amount).to eq(25.00)
      end
    end

    context "without price data" do
      it "returns unavailable price" do
        expect(item.has_price?).to be false
        expect(item.formatted_price).to eq("N/A")
      end
    end
  end
end
```

### Helper Specs

```ruby
# spec/helpers/prices_helper_spec.rb
require "rails_helper"

RSpec.describe PricesHelper, type: :helper do
  describe "#format_price" do
    it "formats USD prices" do
      expect(helper.format_price(10.50, currency: "USD")).to eq("$10.50")
    end

    it "formats small prices with cents" do
      expect(helper.format_price(0.25, currency: "USD")).to eq("$0.25")
    end

    it "formats large prices with commas" do
      expect(helper.format_price(1234.56, currency: "USD")).to eq("$1,234.56")
    end

    it "returns N/A for nil" do
      expect(helper.format_price(nil)).to eq("N/A")
    end

    it "returns N/A for zero" do
      expect(helper.format_price(0)).to eq("N/A")
    end
  end

  describe "#price_source_badge" do
    it "returns human-readable provider name" do
      expect(helper.price_source_badge("tcgplayer")).to include("TCGPlayer")
    end
  end

  describe "#price_freshness_indicator" do
    it "shows 'Updated today' for today's date" do
      result = helper.price_freshness_indicator(Date.current)
      expect(result).to include("Updated today")
    end

    it "shows days old for older dates" do
      result = helper.price_freshness_indicator(3.days.ago.to_date)
      expect(result).to include("3 days ago")
    end

    it "highlights stale prices" do
      result = helper.price_freshness_indicator(10.days.ago.to_date)
      expect(result).to include("amber")
    end
  end
end
```

### Request Specs

```ruby
# spec/requests/items_spec.rb (additions)
RSpec.describe "Items with Prices", type: :request do
  let(:collection) { create(:collection) }
  let(:card) { MTGJSON::Card.first }

  describe "GET /items/:id" do
    let!(:item) { create(:item, collection: collection, card_uuid: card.uuid) }

    context "with price data" do
      before do
        create(:card_price, card_uuid: card.uuid, retail_normal: 5.00)
      end

      it "displays the price" do
        get item_path(item)
        expect(response.body).to include("$5.00")
      end
    end

    context "without price data" do
      it "shows unavailable indicator" do
        get item_path(item)
        expect(response.body).to include("unavailable").or include("N/A")
      end
    end
  end
end
```

### System Specs

```ruby
# spec/system/price_display_spec.rb
require "rails_helper"

RSpec.describe "Price Display", type: :system do
  before { driven_by(:selenium_headless) }

  let(:collection) { create(:collection, name: "Test Collection") }
  let(:card) { MTGJSON::Card.first }

  describe "item detail page" do
    let!(:item) { create(:item, collection: collection, card_uuid: card.uuid, finish: :nonfoil) }

    context "with price data" do
      before do
        create(:card_price,
          card_uuid: card.uuid,
          retail_normal: 12.50,
          retail_foil: 35.00,
          provider: "tcgplayer",
          price_date: Date.current
        )
      end

      it "displays the item price" do
        visit item_path(item)

        expect(page).to have_content("$12.50")
        expect(page).to have_content("TCGPlayer")
      end
    end

    context "without price data" do
      it "shows unavailable message" do
        visit item_path(item)

        expect(page).to have_content("unavailable").or have_content("N/A")
      end
    end
  end

  describe "items list" do
    context "with mixed price availability" do
      before do
        create(:item, collection: collection, card_uuid: card.uuid)
        create(:card_price, card_uuid: card.uuid, retail_normal: 5.00)

        # Create item without price
        other_card = MTGJSON::Card.second
        create(:item, collection: collection, card_uuid: other_card.uuid)
      end

      it "shows prices where available" do
        visit collection_items_path(collection)

        expect(page).to have_content("$5.00")
        expect(page).to have_content("N/A").or have_content("-")
      end
    end
  end
end
```

### Factory

```ruby
# spec/factories/card_prices.rb
FactoryBot.define do
  factory :card_price do
    card_uuid { SecureRandom.uuid }
    provider { "tcgplayer" }
    currency { "USD" }
    retail_normal { 5.00 }
    retail_foil { 15.00 }
    retail_etched { nil }
    buylist_normal { 3.00 }
    buylist_foil { 10.00 }
    buylist_etched { nil }
    price_date { Date.current }
    fetched_at { Time.current }
  end
end
```

---

## UI/UX Specifications

### Card Detail Price Section

```
┌─────────────────────────────────────────┐
│ Market Price                            │
├─────────────────────────────────────────┤
│                                         │
│ Non-foil         $2.50                  │
│ Foil            $12.00                  │
│ Etched           $8.50                  │
│                                         │
├─────────────────────────────────────────┤
│ TCGPlayer      Updated today            │
└─────────────────────────────────────────┘
```

### Item Detail Price Display

```
┌─────────────────────────────────────────┐
│ Your Item Value                         │
├─────────────────────────────────────────┤
│                                         │
│        $12.00                           │
│        Traditional Foil                 │
│                                         │
│ TCGPlayer · Updated today               │
│ Price shown is for Near Mint condition  │
└─────────────────────────────────────────┘
```

### Items List Price Column

```
┌────────┬──────────┬───────────┬─────────┬────────┐
│ Name   │ Set      │ Condition │ Finish  │ Price  │
├────────┼──────────┼───────────┼─────────┼────────┤
│ Card A │ MH3      │ NM        │ Nonfoil │  $2.50 │
│ Card B │ ONE      │ LP        │ Foil    │ $15.00 │
│ Card C │ BRO      │ NM        │ Etched  │    N/A │
└────────┴──────────┴───────────┴─────────┴────────┘
```

### Stale Price Warning

```
┌─────────────────────────────────────────┐
│ ⚠️ Prices may be outdated               │
│                                         │
│ $5.00                                   │
│ TCGPlayer · 12 days old                 │
│                                         │
│ Run `bin/rails prices:import` to update │
└─────────────────────────────────────────┘
```

---

## Dependencies

- **Phase 1.3**: Card Detail View (to display prices)
- **Phase 2.3**: Item Detail View (to display item prices)
- **Phase 2.2**: Item List View (to display price column)
- **Net::HTTP**: For fetching MTGJSON price data
- **WebMock**: For stubbing HTTP requests in tests

---

## Definition of Done

- [ ] CardPrice model with validations and scopes
- [ ] PriceLookup service for retrieving prices
- [ ] PriceImport service for importing MTGJSON prices
- [ ] Rake tasks for price management (`prices:import`, `prices:info`, `prices:clear`)
- [ ] Item model enhanced with `#price`, `#formatted_price` methods
- [ ] Card detail view shows price section
- [ ] Item detail view shows item-specific price
- [ ] Items list shows price column
- [ ] Price source and freshness indicators displayed
- [ ] Stale price warnings shown when appropriate
- [ ] Empty/unavailable price states handled gracefully
- [ ] PricesHelper with formatting methods
- [ ] Factory for CardPrice
- [ ] Model specs for CardPrice
- [ ] Service specs for PriceLookup and PriceImport
- [ ] Helper specs for PricesHelper
- [ ] Request specs for price display
- [ ] System specs for price viewing workflows
- [ ] `bin/ci` passes

---

## Future Enhancements (Not in MVP)

- Multiple provider support (CardMarket, Card Kingdom)
- Currency conversion
- Price history graphs
- Scheduled background price updates (Solid Queue job)
- Price change notifications
- Buylist price comparison
- Condition-adjusted price estimates
- Price filtering in item lists
- TCGPlayer API integration for real-time prices
