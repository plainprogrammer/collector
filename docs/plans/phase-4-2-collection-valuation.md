# Phase 4.2: Collection Valuation

## Feature Overview

Calculate and display the total estimated market value of a collection. This feature aggregates individual card prices to provide collectors with an understanding of their collection's overall worth, broken down by various dimensions.

**Priority**: Medium (completes financial tracking capability)
**Dependencies**: Phase 4.1 (Price Display), Phase 3.3 (Collection Statistics)
**Estimated Complexity**: Medium

---

## User Stories

### US-4.2.1: View Total Collection Value
**As a** collector
**I want to** see the total estimated value of my collection
**So that** I understand what my collection is worth

### US-4.2.2: See Value by Storage Unit
**As a** collector
**I want to** see the value of items in each storage unit
**So that** I know which boxes/binders are most valuable

### US-4.2.3: View Most Valuable Cards
**As a** collector
**I want to** see my most valuable individual cards
**So that** I know which cards to protect or insure

### US-4.2.4: Understand Valuation Methodology
**As a** collector
**I want to** understand how values are calculated
**So that** I can interpret the numbers correctly

### US-4.2.5: See Value Breakdown by Condition
**As a** collector
**I want to** see value breakdown by card condition
**So that** I understand how condition affects my collection's worth

### US-4.2.6: See Items Without Prices
**As a** collector
**I want to** know which items don't have prices
**So that** I understand limitations of the valuation

### US-4.2.7: View Value on Collection Dashboard
**As a** collector
**I want to** see collection value prominently on my collection page
**So that** I can quickly check my collection's worth

### US-4.2.8: Compare Collection Values
**As a** collector
**I want to** see value summaries across all my collections
**So that** I can compare their relative worth

---

## Acceptance Criteria

### AC-4.2.1: Collection Value Summary

```gherkin
Feature: Total Collection Value

  Scenario: Collection with priced items
    Given my collection has 100 items
    And 80 items have prices totaling $500
    When I view the collection valuation
    Then I should see "Total Value: $500.00"
    And I should see "80 of 100 items priced"

  Scenario: Collection with no priced items
    Given my collection has items but no price data
    When I view the collection valuation
    Then I should see "Total Value: $0.00" or "Value unavailable"
    And I should see "0 of X items priced"
    And I should see a notice to import price data

  Scenario: Empty collection
    Given my collection has no items
    When I view the collection valuation
    Then I should see "No items to value"
```

### AC-4.2.2: Value Breakdown Display

```gherkin
Feature: Value Breakdown

  Scenario: Value by storage unit
    Given my collection has storage units with items
    When I view the valuation breakdown
    Then I should see each storage unit's total value
    And storage units should be sorted by value (highest first)

  Scenario: Value by condition
    Given my collection has items in various conditions
    When I view the valuation breakdown
    Then I should see value breakdown by condition
    And I should see:
      | condition    | value    |
      | Near Mint    | $350.00  |
      | Lightly Played | $100.00 |
      | etc.         |          |

  Scenario: Value by finish
    Given my collection has foil and non-foil items
    When I view the valuation breakdown
    Then I should see value breakdown by finish
    And foils should typically show higher values
```

### AC-4.2.3: Most Valuable Cards

```gherkin
Feature: Most Valuable Cards List

  Scenario: Top valuable cards displayed
    Given my collection has priced items
    When I view the most valuable cards section
    Then I should see the top 10 most valuable items
    And each should show card name, set, finish, and price

  Scenario: Duplicate handling
    Given I have 4 copies of a $50 card
    Then the most valuable list should show each copy separately
    Or it should show "Card Name (x4) - $200.00 total"

  Scenario: Click to view item
    Given I see a valuable card in the list
    When I click on it
    Then I should navigate to that item's detail page
```

### AC-4.2.4: Valuation Methodology Explanation

```gherkin
Feature: Methodology Transparency

  Scenario: Methodology displayed
    Given I am viewing the valuation page
    Then I should see an explanation of how values are calculated
    And it should mention:
      | point                                |
      | Prices from TCGPlayer                |
      | Near Mint condition assumed          |
      | Price date/freshness                 |
      | Items without prices are excluded    |

  Scenario: Price date shown
    Given price data was imported on "Jan 15, 2024"
    Then I should see "Prices as of Jan 15, 2024"
```

### AC-4.2.5: Items Without Prices

```gherkin
Feature: Unpriced Items Visibility

  Scenario: Unpriced items count
    Given 20 of 100 items have no price data
    Then I should see "20 items without prices"
    And I should be able to click to view those items

  Scenario: View unpriced items list
    When I click "View items without prices"
    Then I should see a filtered list of unpriced items
    And I can manually assess or research those cards
```

### AC-4.2.6: Collection Dashboard Integration

```gherkin
Feature: Value on Collection Page

  Scenario: Value summary on collection show
    Given my collection has a calculated value
    When I view the collection page
    Then I should see a value summary card
    And it should show total value and item count

  Scenario: Link to full valuation
    Given I see the value summary
    When I click "View Valuation Details"
    Then I should go to the full valuation page
```

### AC-4.2.7: All Collections Overview

```gherkin
Feature: Cross-Collection Comparison

  Scenario: Collections index shows values
    Given I have multiple collections with values
    When I view the collections index
    Then I should see each collection's total value
    And collections can be sorted by value

  Scenario: Grand total across collections
    Given I have 3 collections worth $500, $300, $200
    When I view the collections index
    Then I should see "Total across all collections: $1,000"
```

### AC-4.2.8: Storage Unit Values

```gherkin
Feature: Storage Unit Valuation

  Scenario: Storage unit shows value
    Given a storage unit "Rare Box" has items worth $250
    When I view the storage unit
    Then I should see "Estimated Value: $250"

  Scenario: Nested storage unit value
    Given "Big Box" contains "Deck 1" worth $50 and "Deck 2" worth $30
    And "Big Box" directly contains items worth $20
    Then "Big Box" should show "Total Value: $100"
    And it should show breakdown by nested unit
```

---

## Technical Implementation

### Service Object

```ruby
# app/services/collection_valuation.rb
class CollectionValuation
  attr_reader :collection

  def initialize(collection)
    @collection = collection
    @items = collection.items
    @price_cache = {}
  end

  def total_value
    @total_value ||= calculate_total_value
  end

  def priced_items_count
    @priced_count ||= items_with_prices.count
  end

  def unpriced_items_count
    @items.count - priced_items_count
  end

  def priced_percentage
    return 0 if @items.count.zero?
    ((priced_items_count.to_f / @items.count) * 100).round(1)
  end

  def value_by_storage_unit
    @value_by_storage ||= calculate_value_by_storage_unit
  end

  def value_by_condition
    @value_by_condition ||= calculate_value_by_condition
  end

  def value_by_finish
    @value_by_finish ||= calculate_value_by_finish
  end

  def most_valuable_items(limit: 10)
    @most_valuable ||= calculate_most_valuable(limit)
  end

  def unpriced_items
    @unpriced ||= @items.reject { |item| item_price(item).present? }
  end

  def price_date
    CardPrice.for_provider(CardPrice::DEFAULT_PROVIDER).maximum(:price_date)
  end

  def has_price_data?
    CardPrice.exists?
  end

  private

  def calculate_total_value
    items_with_prices.sum { |item| item_price(item) || 0 }
  end

  def items_with_prices
    @items.select { |item| item_price(item).present? && item_price(item) > 0 }
  end

  def item_price(item)
    @price_cache[item.id] ||= begin
      price_record = CardPrice.default_for(item.card_uuid)
      price_record&.price_for_finish(item.finish)
    end
  end

  def calculate_value_by_storage_unit
    result = Hash.new { |h, k| h[k] = { value: 0, count: 0 } }

    @items.each do |item|
      price = item_price(item)
      next unless price&.positive?

      key = item.storage_unit_id || :loose
      result[key][:value] += price
      result[key][:count] += 1
    end

    # Convert to array with storage unit info
    result.map do |key, data|
      storage_unit = key == :loose ? nil : StorageUnit.find_by(id: key)
      {
        storage_unit: storage_unit,
        name: storage_unit&.name || "Loose Items",
        value: data[:value],
        count: data[:count]
      }
    end.sort_by { |h| -h[:value] }
  end

  def calculate_value_by_condition
    result = Item.conditions.keys.index_with { { value: 0, count: 0 } }

    @items.each do |item|
      price = item_price(item)
      next unless price&.positive?

      result[item.condition][:value] += price
      result[item.condition][:count] += 1
    end

    result.reject { |_, v| v[:count].zero? }
          .sort_by { |_, v| -v[:value] }
          .to_h
  end

  def calculate_value_by_finish
    result = Item.finishes.keys.index_with { { value: 0, count: 0 } }

    @items.each do |item|
      price = item_price(item)
      next unless price&.positive?

      result[item.finish][:value] += price
      result[item.finish][:count] += 1
    end

    result.reject { |_, v| v[:count].zero? }
          .sort_by { |_, v| -v[:value] }
          .to_h
  end

  def calculate_most_valuable(limit)
    @items
      .map { |item| { item: item, price: item_price(item) } }
      .select { |h| h[:price]&.positive? }
      .sort_by { |h| -h[:price] }
      .first(limit)
  end
end
```

### Storage Unit Valuation

```ruby
# app/services/storage_unit_valuation.rb
class StorageUnitValuation
  def initialize(storage_unit)
    @storage_unit = storage_unit
    @price_cache = {}
  end

  def direct_value
    @direct_value ||= calculate_value(@storage_unit.items)
  end

  def total_value
    @total_value ||= calculate_value(all_items)
  end

  def nested_breakdown
    return [] unless @storage_unit.children.any?

    @storage_unit.children.map do |child|
      child_valuation = StorageUnitValuation.new(child)
      {
        storage_unit: child,
        value: child_valuation.total_value,
        count: child.total_items_count
      }
    end.sort_by { |h| -h[:value] }
  end

  def priced_count
    all_items.count { |item| item_price(item).present? }
  end

  private

  def all_items
    @all_items ||= @storage_unit.all_items.to_a
  end

  def calculate_value(items)
    items.sum { |item| item_price(item) || 0 }
  end

  def item_price(item)
    @price_cache[item.id] ||= begin
      price_record = CardPrice.default_for(item.card_uuid)
      price_record&.price_for_finish(item.finish)
    end
  end
end
```

### Controller

```ruby
# app/controllers/collections_controller.rb (additions)
class CollectionsController < ApplicationController
  def valuation
    @collection = Collection.find(params[:id])
    @valuation = Rails.cache.fetch(
      "collection_valuation_#{@collection.id}_#{@collection.updated_at}",
      expires_in: 15.minutes
    ) do
      CollectionValuation.new(@collection)
    end
  end
end
```

```ruby
# app/controllers/storage_units_controller.rb (additions)
class StorageUnitsController < ApplicationController
  def show
    @storage_unit = StorageUnit.find(params[:id])
    @collection = @storage_unit.collection
    @valuation = StorageUnitValuation.new(@storage_unit)

    # ... existing code ...
  end
end
```

### Model Enhancements

```ruby
# app/models/collection.rb (additions)
class Collection < ApplicationRecord
  def total_value
    @total_value ||= CollectionValuation.new(self).total_value
  end

  def has_valued_items?
    items.joins("INNER JOIN card_prices ON card_prices.card_uuid = items.card_uuid")
         .exists?
  end
end
```

### Helper Methods

```ruby
# app/helpers/valuation_helper.rb
module ValuationHelper
  def format_valuation(amount)
    return "—" if amount.nil? || amount <= 0
    number_to_currency(amount, precision: 2)
  end

  def valuation_coverage_badge(priced, total)
    percentage = total.zero? ? 0 : ((priced.to_f / total) * 100).round

    color = case percentage
            when 90..100 then "green"
            when 70..89 then "lime"
            when 50..69 then "yellow"
            else "red"
            end

    content_tag(:span, "#{percentage}% priced",
      class: "text-xs px-2 py-1 rounded-full bg-#{color}-100 text-#{color}-800")
  end

  def value_bar_width(value, max_value)
    return 0 if max_value.zero?
    ((value.to_f / max_value) * 100).round
  end

  def condition_value_note
    "Values shown assume Near Mint condition. " \
    "Actual value may vary based on card condition."
  end

  def valuation_methodology_text
    <<~TEXT
      Collection values are calculated using market prices from TCGPlayer.
      Each item's price is determined by its card printing and finish type
      (foil, non-foil, or etched). Prices reflect Near Mint condition—actual
      resale value may differ based on condition. Items without available
      pricing data are excluded from the total.
    TEXT
  end
end
```

### Routes

```ruby
# config/routes.rb (additions)
resources :collections do
  member do
    get :valuation
  end
  # ... existing routes ...
end
```

### Views

```erb
<%# app/views/collections/valuation.html.erb %>
<% content_for :title, "Valuation - #{@collection.name}" %>

<article class="w-full">
  <nav class="mb-6">
    <%= link_to @collection, class: "inline-flex items-center gap-1 text-indigo-600 hover:text-indigo-800" do %>
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
      </svg>
      Back to <%= @collection.name %>
    <% end %>
  </nav>

  <header class="mb-8">
    <h1 class="text-3xl font-bold text-gray-900">Collection Valuation</h1>
    <p class="mt-1 text-gray-600"><%= @collection.name %></p>
  </header>

  <% unless @valuation.has_price_data? %>
    <div class="mb-8 p-4 bg-amber-50 border border-amber-200 rounded-lg">
      <div class="flex items-start gap-3">
        <svg class="w-5 h-5 text-amber-600 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
        </svg>
        <div>
          <h3 class="font-medium text-amber-800">No price data available</h3>
          <p class="mt-1 text-sm text-amber-700">
            Import pricing data to see collection values:
            <code class="bg-amber-100 px-1 rounded">bin/rails prices:import</code>
          </p>
        </div>
      </div>
    </div>
  <% end %>

  <!-- Value Summary -->
  <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
    <div class="lg:col-span-2 bg-white rounded-lg border border-gray-200 p-6">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">Total Value</h2>

      <div class="flex items-baseline gap-4">
        <span class="text-5xl font-bold text-gray-900">
          <%= format_valuation(@valuation.total_value) %>
        </span>
        <%= valuation_coverage_badge(@valuation.priced_items_count, @collection.items.count) %>
      </div>

      <p class="mt-4 text-sm text-gray-600">
        <%= @valuation.priced_items_count %> of <%= @collection.items.count %> items have prices
        <% if @valuation.unpriced_items_count > 0 %>
          · <%= link_to "#{@valuation.unpriced_items_count} items without prices",
              collection_items_path(@collection, unpriced: true),
              class: "text-indigo-600 hover:text-indigo-800" %>
        <% end %>
      </p>

      <% if @valuation.price_date %>
        <p class="mt-2 text-xs text-gray-500">
          Prices as of <%= @valuation.price_date.strftime("%B %d, %Y") %>
        </p>
      <% end %>
    </div>

    <div class="bg-gray-50 rounded-lg border border-gray-200 p-6">
      <h3 class="text-sm font-medium text-gray-700 mb-3">How Values Are Calculated</h3>
      <p class="text-xs text-gray-600 leading-relaxed">
        <%= valuation_methodology_text %>
      </p>
    </div>
  </div>

  <div class="grid lg:grid-cols-2 gap-8">
    <!-- Most Valuable Cards -->
    <section class="bg-white rounded-lg border border-gray-200 p-6">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">Most Valuable Cards</h2>

      <% if @valuation.most_valuable_items.any? %>
        <div class="space-y-3">
          <% @valuation.most_valuable_items.each_with_index do |entry, index| %>
            <% item = entry[:item] %>
            <% card = item.card %>
            <%= link_to item_path(item),
                class: "flex items-center gap-3 p-2 -mx-2 rounded-lg hover:bg-gray-50 transition-colors" do %>
              <span class="text-sm font-medium text-gray-400 w-5"><%= index + 1 %></span>
              <div class="flex-1 min-w-0">
                <p class="font-medium text-gray-900 truncate"><%= card&.name || "Unknown Card" %></p>
                <p class="text-xs text-gray-500">
                  <%= card&.setCode %> ·
                  <%= item.finish.humanize %> ·
                  <%= condition_display_name(item.condition) %>
                </p>
              </div>
              <span class="font-semibold text-gray-900">
                <%= format_valuation(entry[:price]) %>
              </span>
            <% end %>
          <% end %>
        </div>
      <% else %>
        <p class="text-gray-500 text-sm">No priced items to display</p>
      <% end %>
    </section>

    <!-- Value by Storage Unit -->
    <section class="bg-white rounded-lg border border-gray-200 p-6">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">Value by Storage</h2>

      <% storage_values = @valuation.value_by_storage_unit %>
      <% max_value = storage_values.map { |h| h[:value] }.max || 0 %>

      <% if storage_values.any? %>
        <div class="space-y-3">
          <% storage_values.first(8).each do |entry| %>
            <div class="flex items-center justify-between">
              <% if entry[:storage_unit] %>
                <%= link_to entry[:name], entry[:storage_unit],
                    class: "font-medium text-gray-900 hover:text-indigo-600 truncate" %>
              <% else %>
                <span class="font-medium text-gray-900"><%= entry[:name] %></span>
              <% end %>
              <div class="flex items-center gap-2 flex-shrink-0">
                <div class="w-20 bg-gray-100 rounded-full h-2">
                  <div class="bg-indigo-500 h-2 rounded-full"
                       style="width: <%= value_bar_width(entry[:value], max_value) %>%"></div>
                </div>
                <span class="text-sm font-medium text-gray-900 w-20 text-right">
                  <%= format_valuation(entry[:value]) %>
                </span>
              </div>
            </div>
          <% end %>

          <% if storage_values.size > 8 %>
            <p class="text-sm text-gray-500 pt-2">
              + <%= storage_values.size - 8 %> more storage units
            </p>
          <% end %>
        </div>
      <% else %>
        <p class="text-gray-500 text-sm">No valued items in storage</p>
      <% end %>
    </section>

    <!-- Value by Condition -->
    <section class="bg-white rounded-lg border border-gray-200 p-6">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">Value by Condition</h2>

      <% condition_values = @valuation.value_by_condition %>
      <% max_value = condition_values.values.map { |h| h[:value] }.max || 0 %>

      <% if condition_values.any? %>
        <div class="space-y-3">
          <% condition_values.each do |condition, data| %>
            <div class="flex items-center justify-between">
              <%= link_to condition_display_name(condition),
                  collection_items_path(@collection, condition: condition),
                  class: "font-medium text-gray-900 hover:text-indigo-600" %>
              <div class="flex items-center gap-2">
                <span class="text-xs text-gray-500"><%= data[:count] %> items</span>
                <div class="w-16 bg-gray-100 rounded-full h-2">
                  <div class="<%= condition_bar_class(condition) %> h-2 rounded-full"
                       style="width: <%= value_bar_width(data[:value], max_value) %>%"></div>
                </div>
                <span class="text-sm font-medium text-gray-900 w-20 text-right">
                  <%= format_valuation(data[:value]) %>
                </span>
              </div>
            </div>
          <% end %>
        </div>

        <p class="mt-4 text-xs text-gray-500">
          <%= condition_value_note %>
        </p>
      <% else %>
        <p class="text-gray-500 text-sm">No condition data available</p>
      <% end %>
    </section>

    <!-- Value by Finish -->
    <section class="bg-white rounded-lg border border-gray-200 p-6">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">Value by Finish</h2>

      <% finish_values = @valuation.value_by_finish %>
      <% max_value = finish_values.values.map { |h| h[:value] }.max || 0 %>

      <% if finish_values.any? %>
        <div class="space-y-3">
          <% finish_values.each do |finish, data| %>
            <div class="flex items-center justify-between">
              <%= link_to finish.humanize.titleize,
                  collection_items_path(@collection, finish: finish),
                  class: "font-medium text-gray-900 hover:text-indigo-600" %>
              <div class="flex items-center gap-2">
                <span class="text-xs text-gray-500"><%= data[:count] %> items</span>
                <div class="w-16 bg-gray-100 rounded-full h-2">
                  <div class="<%= finish == "nonfoil" ? "bg-gray-400" : "bg-gradient-to-r from-yellow-400 to-orange-400" %> h-2 rounded-full"
                       style="width: <%= value_bar_width(data[:value], max_value) %>%"></div>
                </div>
                <span class="text-sm font-medium text-gray-900 w-20 text-right">
                  <%= format_valuation(data[:value]) %>
                </span>
              </div>
            </div>
          <% end %>
        </div>
      <% else %>
        <p class="text-gray-500 text-sm">No finish data available</p>
      <% end %>
    </section>
  </div>
</article>
```

```erb
<%# app/views/collections/_value_summary.html.erb %>
<%# Partial for collection show page %>
<% if collection.items.any? %>
  <div class="bg-white rounded-lg border border-gray-200 p-4">
    <div class="flex items-center justify-between">
      <div>
        <h3 class="text-sm font-medium text-gray-500">Estimated Value</h3>
        <p class="text-2xl font-bold text-gray-900">
          <%= format_valuation(collection.total_value) %>
        </p>
      </div>
      <%= link_to valuation_collection_path(collection),
          class: "text-sm text-indigo-600 hover:text-indigo-800" do %>
        View Details
        <svg class="w-4 h-4 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
      <% end %>
    </div>
  </div>
<% end %>
```

```erb
<%# app/views/storage_units/_value_display.html.erb %>
<%# Partial for storage unit show page %>
<% if @valuation.priced_count > 0 %>
  <div class="bg-indigo-50 rounded-lg p-4 mb-4">
    <div class="flex items-center justify-between">
      <div>
        <p class="text-sm text-indigo-600">Estimated Value</p>
        <p class="text-xl font-bold text-indigo-900">
          <%= format_valuation(@valuation.total_value) %>
        </p>
        <% if @valuation.direct_value != @valuation.total_value %>
          <p class="text-xs text-indigo-600">
            Direct: <%= format_valuation(@valuation.direct_value) %> ·
            Nested: <%= format_valuation(@valuation.total_value - @valuation.direct_value) %>
          </p>
        <% end %>
      </div>
      <p class="text-xs text-indigo-500"><%= @valuation.priced_count %> items priced</p>
    </div>
  </div>
<% end %>
```

---

## Database Changes

None required. This feature uses existing Item and CardPrice tables.

---

## Test Requirements

### Service Specs

```ruby
# spec/services/collection_valuation_spec.rb
require "rails_helper"

RSpec.describe CollectionValuation do
  let(:collection) { create(:collection) }
  let(:card1) { MTGJSON::Card.first }
  let(:card2) { MTGJSON::Card.second }

  subject { described_class.new(collection) }

  describe "#total_value" do
    context "with priced items" do
      before do
        create(:item, collection: collection, card_uuid: card1.uuid, finish: :nonfoil)
        create(:item, collection: collection, card_uuid: card2.uuid, finish: :traditional_foil)
        create(:card_price, card_uuid: card1.uuid, retail_normal: 10.00)
        create(:card_price, card_uuid: card2.uuid, retail_foil: 25.00)
      end

      it "sums all item prices" do
        expect(subject.total_value).to eq(35.00)
      end
    end

    context "with mixed priced and unpriced items" do
      before do
        create(:item, collection: collection, card_uuid: card1.uuid)
        create(:item, collection: collection, card_uuid: card2.uuid)
        create(:card_price, card_uuid: card1.uuid, retail_normal: 10.00)
        # No price for card2
      end

      it "only includes priced items" do
        expect(subject.total_value).to eq(10.00)
      end
    end

    context "with no priced items" do
      before do
        create(:item, collection: collection, card_uuid: card1.uuid)
      end

      it "returns zero" do
        expect(subject.total_value).to eq(0)
      end
    end

    context "with empty collection" do
      it "returns zero" do
        expect(subject.total_value).to eq(0)
      end
    end
  end

  describe "#priced_items_count" do
    before do
      create(:item, collection: collection, card_uuid: card1.uuid)
      create(:item, collection: collection, card_uuid: card2.uuid)
      create(:card_price, card_uuid: card1.uuid, retail_normal: 10.00)
    end

    it "returns count of items with prices" do
      expect(subject.priced_items_count).to eq(1)
    end
  end

  describe "#unpriced_items_count" do
    before do
      create(:item, collection: collection, card_uuid: card1.uuid)
      create(:item, collection: collection, card_uuid: card2.uuid)
      create(:card_price, card_uuid: card1.uuid, retail_normal: 10.00)
    end

    it "returns count of items without prices" do
      expect(subject.unpriced_items_count).to eq(1)
    end
  end

  describe "#value_by_storage_unit" do
    let(:storage_unit) { create(:storage_unit, collection: collection, name: "Box A") }

    before do
      create(:item, collection: collection, storage_unit: storage_unit, card_uuid: card1.uuid)
      create(:item, collection: collection, storage_unit: nil, card_uuid: card2.uuid)
      create(:card_price, card_uuid: card1.uuid, retail_normal: 20.00)
      create(:card_price, card_uuid: card2.uuid, retail_normal: 10.00)
    end

    it "groups values by storage unit" do
      result = subject.value_by_storage_unit
      box_entry = result.find { |h| h[:name] == "Box A" }
      loose_entry = result.find { |h| h[:name] == "Loose Items" }

      expect(box_entry[:value]).to eq(20.00)
      expect(loose_entry[:value]).to eq(10.00)
    end

    it "sorts by value descending" do
      result = subject.value_by_storage_unit
      expect(result.first[:value]).to be >= result.last[:value]
    end
  end

  describe "#value_by_condition" do
    before do
      create(:item, collection: collection, card_uuid: card1.uuid, condition: :near_mint)
      create(:item, collection: collection, card_uuid: card2.uuid, condition: :lightly_played)
      create(:card_price, card_uuid: card1.uuid, retail_normal: 20.00)
      create(:card_price, card_uuid: card2.uuid, retail_normal: 15.00)
    end

    it "groups values by condition" do
      result = subject.value_by_condition
      expect(result["near_mint"][:value]).to eq(20.00)
      expect(result["lightly_played"][:value]).to eq(15.00)
    end
  end

  describe "#value_by_finish" do
    before do
      create(:item, collection: collection, card_uuid: card1.uuid, finish: :nonfoil)
      create(:item, collection: collection, card_uuid: card2.uuid, finish: :traditional_foil)
      create(:card_price, card_uuid: card1.uuid, retail_normal: 5.00, retail_foil: 15.00)
      create(:card_price, card_uuid: card2.uuid, retail_normal: 8.00, retail_foil: 25.00)
    end

    it "groups values by finish" do
      result = subject.value_by_finish
      expect(result["nonfoil"][:value]).to eq(5.00)
      expect(result["traditional_foil"][:value]).to eq(25.00)
    end
  end

  describe "#most_valuable_items" do
    before do
      create(:item, collection: collection, card_uuid: card1.uuid)
      create(:item, collection: collection, card_uuid: card2.uuid)
      create(:card_price, card_uuid: card1.uuid, retail_normal: 100.00)
      create(:card_price, card_uuid: card2.uuid, retail_normal: 50.00)
    end

    it "returns items sorted by value" do
      result = subject.most_valuable_items(limit: 10)
      expect(result.first[:price]).to eq(100.00)
      expect(result.second[:price]).to eq(50.00)
    end

    it "respects limit parameter" do
      result = subject.most_valuable_items(limit: 1)
      expect(result.size).to eq(1)
    end
  end
end
```

```ruby
# spec/services/storage_unit_valuation_spec.rb
require "rails_helper"

RSpec.describe StorageUnitValuation do
  let(:collection) { create(:collection) }
  let(:storage_unit) { create(:storage_unit, collection: collection) }
  let(:card) { MTGJSON::Card.first }

  subject { described_class.new(storage_unit) }

  describe "#direct_value" do
    before do
      create(:item, collection: collection, storage_unit: storage_unit, card_uuid: card.uuid)
      create(:card_price, card_uuid: card.uuid, retail_normal: 20.00)
    end

    it "returns value of items directly in unit" do
      expect(subject.direct_value).to eq(20.00)
    end
  end

  describe "#total_value" do
    let(:nested) { create(:storage_unit, collection: collection, parent: storage_unit) }
    let(:card2) { MTGJSON::Card.second }

    before do
      create(:item, collection: collection, storage_unit: storage_unit, card_uuid: card.uuid)
      create(:item, collection: collection, storage_unit: nested, card_uuid: card2.uuid)
      create(:card_price, card_uuid: card.uuid, retail_normal: 20.00)
      create(:card_price, card_uuid: card2.uuid, retail_normal: 15.00)
    end

    it "includes nested unit values" do
      expect(subject.total_value).to eq(35.00)
    end
  end

  describe "#nested_breakdown" do
    let(:nested1) { create(:storage_unit, collection: collection, parent: storage_unit, name: "Deck 1") }
    let(:nested2) { create(:storage_unit, collection: collection, parent: storage_unit, name: "Deck 2") }
    let(:card2) { MTGJSON::Card.second }

    before do
      create(:item, collection: collection, storage_unit: nested1, card_uuid: card.uuid)
      create(:item, collection: collection, storage_unit: nested2, card_uuid: card2.uuid)
      create(:card_price, card_uuid: card.uuid, retail_normal: 30.00)
      create(:card_price, card_uuid: card2.uuid, retail_normal: 20.00)
    end

    it "returns breakdown of nested unit values" do
      result = subject.nested_breakdown
      expect(result.size).to eq(2)
      expect(result.first[:value]).to eq(30.00)  # sorted by value desc
    end
  end
end
```

### Request Specs

```ruby
# spec/requests/collection_valuation_spec.rb
require "rails_helper"

RSpec.describe "Collection Valuation", type: :request do
  let(:collection) { create(:collection, name: "Test Collection") }
  let(:card) { MTGJSON::Card.first }

  describe "GET /collections/:id/valuation" do
    context "with priced items" do
      before do
        create_list(:item, 3, collection: collection, card_uuid: card.uuid)
        create(:card_price, card_uuid: card.uuid, retail_normal: 10.00)
      end

      it "returns successful response" do
        get valuation_collection_path(collection)
        expect(response).to have_http_status(:ok)
      end

      it "displays total value" do
        get valuation_collection_path(collection)
        expect(response.body).to include("$30.00")
      end

      it "displays priced items count" do
        get valuation_collection_path(collection)
        expect(response.body).to include("3 of 3")
      end
    end

    context "without price data" do
      before do
        create(:item, collection: collection, card_uuid: card.uuid)
      end

      it "shows no price data notice" do
        get valuation_collection_path(collection)
        expect(response.body).to include("No price data")
      end
    end

    context "empty collection" do
      it "shows appropriate message" do
        get valuation_collection_path(collection)
        expect(response.body).to include("No items")
      end
    end
  end
end
```

### System Specs

```ruby
# spec/system/collection_valuation_spec.rb
require "rails_helper"

RSpec.describe "Collection Valuation", type: :system do
  before { driven_by(:selenium_headless) }

  let(:collection) { create(:collection, name: "My Collection") }
  let(:card) { MTGJSON::Card.first }

  describe "viewing collection valuation" do
    context "with valued items" do
      before do
        create(:item, collection: collection, card_uuid: card.uuid, finish: :nonfoil)
        create(:item, collection: collection, card_uuid: card.uuid, finish: :traditional_foil)
        create(:card_price,
          card_uuid: card.uuid,
          retail_normal: 10.00,
          retail_foil: 30.00,
          price_date: Date.current
        )
      end

      it "displays total collection value" do
        visit valuation_collection_path(collection)

        expect(page).to have_content("$40.00")
        expect(page).to have_content("2 of 2 items")
      end

      it "displays most valuable cards" do
        visit valuation_collection_path(collection)

        expect(page).to have_content("Most Valuable Cards")
        expect(page).to have_content(card.name)
      end

      it "displays value by finish" do
        visit valuation_collection_path(collection)

        expect(page).to have_content("Value by Finish")
        expect(page).to have_content("Nonfoil")
        expect(page).to have_content("Traditional foil")
      end
    end

    context "with unpriced items" do
      let(:other_card) { MTGJSON::Card.second }

      before do
        create(:item, collection: collection, card_uuid: card.uuid)
        create(:item, collection: collection, card_uuid: other_card.uuid)
        create(:card_price, card_uuid: card.uuid, retail_normal: 20.00)
        # No price for other_card
      end

      it "shows unpriced items count" do
        visit valuation_collection_path(collection)

        expect(page).to have_content("1 of 2 items")
        expect(page).to have_link("1 items without prices")
      end
    end

    context "navigating from collection page" do
      before do
        create(:item, collection: collection, card_uuid: card.uuid)
        create(:card_price, card_uuid: card.uuid, retail_normal: 50.00)
      end

      it "links to valuation from collection show" do
        visit collection_path(collection)

        click_link "View Details"

        expect(page).to have_current_path(valuation_collection_path(collection))
      end
    end
  end

  describe "methodology explanation" do
    before do
      create(:item, collection: collection, card_uuid: card.uuid)
      create(:card_price, card_uuid: card.uuid, retail_normal: 10.00)
    end

    it "displays valuation methodology" do
      visit valuation_collection_path(collection)

      expect(page).to have_content("How Values Are Calculated")
      expect(page).to have_content("TCGPlayer")
      expect(page).to have_content("Near Mint")
    end
  end
end
```

### Helper Specs

```ruby
# spec/helpers/valuation_helper_spec.rb
require "rails_helper"

RSpec.describe ValuationHelper, type: :helper do
  describe "#format_valuation" do
    it "formats positive amounts" do
      expect(helper.format_valuation(100.50)).to eq("$100.50")
    end

    it "returns dash for nil" do
      expect(helper.format_valuation(nil)).to eq("—")
    end

    it "returns dash for zero" do
      expect(helper.format_valuation(0)).to eq("—")
    end
  end

  describe "#valuation_coverage_badge" do
    it "shows green for high coverage" do
      result = helper.valuation_coverage_badge(95, 100)
      expect(result).to include("green")
      expect(result).to include("95%")
    end

    it "shows red for low coverage" do
      result = helper.valuation_coverage_badge(30, 100)
      expect(result).to include("red")
    end
  end

  describe "#value_bar_width" do
    it "calculates percentage width" do
      expect(helper.value_bar_width(50, 100)).to eq(50)
    end

    it "handles zero max" do
      expect(helper.value_bar_width(50, 0)).to eq(0)
    end
  end
end
```

---

## UI/UX Specifications

### Valuation Dashboard

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ ← Back to My Collection                                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│ Collection Valuation                                                        │
│ My Collection                                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│ ┌────────────────────────────────────────────┐ ┌───────────────────────────┐│
│ │ Total Value                                │ │ How Values Are Calculated ││
│ │                                            │ │                           ││
│ │         $1,234.56         [95% priced]     │ │ Values calculated using   ││
│ │                                            │ │ TCGPlayer market prices.  ││
│ │ 95 of 100 items have prices                │ │ Prices reflect Near Mint  ││
│ │ · 5 items without prices                   │ │ condition. Items without  ││
│ │                                            │ │ prices are excluded.      ││
│ │ Prices as of January 15, 2024              │ │                           ││
│ └────────────────────────────────────────────┘ └───────────────────────────┘│
│                                                                             │
├────────────────────────────────┬────────────────────────────────────────────┤
│ Most Valuable Cards            │ Value by Storage                           │
│                                │                                            │
│ 1. Black Lotus                 │ Rare Box     ████████████ $450.00          │
│    LEA · Nonfoil · NM          │ Commander... ██████████   $380.00          │
│                       $500.00  │ Trade Bind...████████     $250.00          │
│                                │ Loose Items  ████         $154.56          │
│ 2. Mox Sapphire                │                                            │
│    LEA · Nonfoil · NM          │ + 4 more storage units                     │
│                       $350.00  │                                            │
│                                │                                            │
│ 3. Mox Pearl                   │                                            │
│    LEA · Nonfoil · NM          │                                            │
│                       $280.00  │                                            │
│                                │                                            │
│ ...                            │                                            │
├────────────────────────────────┼────────────────────────────────────────────┤
│ Value by Condition             │ Value by Finish                            │
│                                │                                            │
│ Near Mint    ████████ $980.00  │ Nonfoil     ████████ $800.00               │
│ LP           ████     $200.00  │ Foil        ██████   $384.56               │
│ MP           ██        $54.56  │ Etched      ██        $50.00               │
│                                │                                            │
│ Note: Values shown assume      │                                            │
│ Near Mint condition.           │                                            │
└────────────────────────────────┴────────────────────────────────────────────┘
```

### Value Summary Card (Collection Page)

```
┌────────────────────────────────────────┐
│ Estimated Value                        │
│                                        │
│ $1,234.56          View Details →      │
│                                        │
└────────────────────────────────────────┘
```

### Storage Unit Value Display

```
┌────────────────────────────────────────┐
│ Estimated Value                        │
│ $450.00                                │
│ Direct: $350.00 · Nested: $100.00      │
│ 45 items priced                        │
└────────────────────────────────────────┘
```

---

## Dependencies

- **Phase 4.1**: Price Display (CardPrice model, price lookup)
- **Phase 3.3**: Collection Statistics (similar UI patterns)
- **Phase 3.2**: Storage Unit Contents (storage unit valuation)
- **Rails.cache**: For caching valuations

---

## Definition of Done

- [ ] CollectionValuation service with full functionality
- [ ] StorageUnitValuation service for storage values
- [ ] Valuation route and controller action
- [ ] Total value calculation accurate for all finishes
- [ ] Most valuable cards list displayed
- [ ] Value breakdown by storage unit
- [ ] Value breakdown by condition
- [ ] Value breakdown by finish
- [ ] Unpriced items count and link to view them
- [ ] Valuation methodology explanation displayed
- [ ] Price date/freshness shown
- [ ] Value summary on collection show page
- [ ] Value display on storage unit show page
- [ ] Caching for valuation calculations
- [ ] ValuationHelper with formatting methods
- [ ] Service specs for CollectionValuation
- [ ] Service specs for StorageUnitValuation
- [ ] Helper specs for ValuationHelper
- [ ] Request specs for valuation endpoint
- [ ] System specs for valuation workflows
- [ ] `bin/ci` passes

---

## Future Enhancements (Not in MVP)

- Historical value tracking over time
- Value change notifications
- Condition-adjusted value estimates
- Insurance report generation (PDF)
- Collection value comparison charts
- Set completion value analysis
- "What if I sold..." scenario calculator
- Price alert thresholds
- Export valuation as CSV/PDF
- Portfolio-style value charts
