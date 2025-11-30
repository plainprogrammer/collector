# Phase 1.3: Card Detail View

## Feature Overview

Display comprehensive card information from the MTGJSON database, including card image, rules text, format legalities, and official rulings. This page serves as the launching point for Phase 2's "Add to Collection" functionality.

**Priority**: High (completes card discovery flow)
**Dependencies**: Phase 1.1 (Set Browser), Phase 1.2 (Card Search)
**Estimated Complexity**: Medium-High

---

## User Stories

### US-1.3.1: View Card Details
**As a** collector
**I want to** see complete card information
**So that** I can identify cards and understand their attributes

### US-1.3.2: View Card Image
**As a** collector
**I want to** see the card image
**So that** I can visually identify the card and its artwork

### US-1.3.3: View Format Legalities
**As a** collector
**I want to** see which formats a card is legal in
**So that** I know where I can play the card

### US-1.3.4: View Official Rulings
**As a** collector
**I want to** see official rulings for a card
**So that** I understand how the card works

### US-1.3.5: View Other Printings
**As a** collector
**I want to** see other printings of the same card
**So that** I can find alternative versions

### US-1.3.6: Navigate to Related Content
**As a** collector
**I want to** navigate to the card's set or search for similar cards
**So that** I can explore related content

---

## Acceptance Criteria

### AC-1.3.1: Card Information Display

```gherkin
Feature: Card Information Display

  Scenario: View basic card details
    Given a card "Lightning Bolt" exists in set "LEA"
    When I visit the card detail page
    Then I should see:
      | field       | value                              |
      | name        | "Lightning Bolt"                   |
      | mana cost   | "{R}"                              |
      | type        | "Instant"                          |
      | rules text  | "Lightning Bolt deals 3 damage..." |
      | set name    | "Limited Edition Alpha"            |
      | set code    | "LEA"                              |
      | rarity      | "Common"                           |
      | artist      | "Christopher Rush"                 |
      | number      | "161"                              |

  Scenario: View creature card
    Given a creature card "Serra Angel" exists
    When I visit the card detail page
    Then I should see power "4" and toughness "4"

  Scenario: View planeswalker card
    Given a planeswalker "Jace, the Mind Sculptor" exists
    When I visit the card detail page
    Then I should see loyalty "3"

  Scenario: Card not found
    When I visit a card detail page with invalid UUID
    Then I should see a 404 error
    Or I should be redirected to the cards search with an error message
```

### AC-1.3.2: Card Image Display

```gherkin
Feature: Card Image Display

  Scenario: Display card image from Scryfall
    Given a card has a Scryfall ID
    When I visit the card detail page
    Then I should see the card image from Scryfall CDN
    And the image should have alt text with the card name

  Scenario: Card without Scryfall ID
    Given a card has no Scryfall ID
    When I visit the card detail page
    Then I should see a placeholder image
    And a message "Image not available"

  Scenario: Image loading error
    Given the Scryfall CDN is unavailable
    When I visit the card detail page
    Then I should see a placeholder image
    And the page should still function normally

  Scenario: Double-faced card
    Given a double-faced card "Delver of Secrets" exists
    When I visit the card detail page
    Then I should see both faces of the card
    Or I should see a way to toggle between faces
```

### AC-1.3.3: Format Legalities

```gherkin
Feature: Format Legalities

  Scenario: Display format legalities
    Given "Lightning Bolt" is legal in Modern and Legacy
    And "Lightning Bolt" is not legal in Standard
    When I visit the card detail page
    Then I should see a legalities section
    And I should see "Modern: Legal"
    And I should see "Legacy: Legal"
    And I should see "Standard: Not Legal" or it should be omitted

  Scenario: Display banned/restricted status
    Given "Black Lotus" is banned in Legacy
    And "Black Lotus" is restricted in Vintage
    When I visit the card detail page
    Then I should see "Legacy: Banned"
    And I should see "Vintage: Restricted"

  Scenario: Card with no legalities
    Given a promo card with no format legalities
    When I visit the card detail page
    Then I should see "Not legal in any format"
    Or the legalities section should be hidden
```

### AC-1.3.4: Official Rulings

```gherkin
Feature: Official Rulings

  Scenario: Display rulings
    Given "Lightning Bolt" has 2 rulings
    When I visit the card detail page
    Then I should see a rulings section
    And I should see 2 ruling entries
    And each ruling should show:
      | field | format         |
      | date  | "YYYY-MM-DD"   |
      | text  | ruling content |

  Scenario: Card with no rulings
    Given a vanilla creature with no rulings
    When I visit the card detail page
    Then the rulings section should not appear
    Or it should show "No rulings for this card"

  Scenario: Many rulings
    Given a complex card has 15 rulings
    When I visit the card detail page
    Then I should see all rulings
    And they should be in chronological order (newest first)
```

### AC-1.3.5: Other Printings

```gherkin
Feature: Other Printings

  Scenario: Display other printings
    Given "Lightning Bolt" has 30+ printings
    When I visit the card detail page
    Then I should see an "Other Printings" section
    And I should see a list of sets where this card appears
    And each printing should link to that card version

  Scenario: Unique card (single printing)
    Given a card exists in only one set
    When I visit the card detail page
    Then the "Other Printings" section should not appear
    Or it should show "This is the only printing"

  Scenario: Navigate to other printing
    Given I am viewing "Lightning Bolt" from "LEA"
    When I click on the "Modern Horizons 2" printing
    Then I should be on the card detail page for the MH2 version
```

### AC-1.3.6: Navigation

```gherkin
Feature: Card Detail Navigation

  Scenario: Navigate to set
    Given I am viewing a card from "Modern Horizons 3"
    When I click on the set name
    Then I should be on the set detail page for MH3

  Scenario: Back to search results
    Given I came from a search for "Lightning"
    When I click "Back to Search"
    Then I should return to the search results
    And my search should be preserved

  Scenario: Back to set
    Given I came from the MH3 set page
    When I click "Back to Set"
    Then I should return to the MH3 set page
```

---

## Technical Implementation

### Routes

```ruby
# config/routes.rb
resources :cards, only: [:index, :show], param: :uuid
```

**Route generated:**
- `GET /cards/:uuid` → `cards#show`

### Controller

```ruby
# app/controllers/cards_controller.rb
class CardsController < ApplicationController
  def show
    @card = MTGJSON::Card.includes(:set, :identifiers, :legalities, :rulings)
                         .find_by!(uuid: params[:uuid])
    @other_printings = find_other_printings(@card)
  rescue ActiveRecord::RecordNotFound
    redirect_to cards_path, alert: "Card not found"
  end

  private

  def find_other_printings(card)
    # Find cards with same name but different UUID
    MTGJSON::Card.includes(:set)
                 .where(name: card.name)
                 .where.not(uuid: card.uuid)
                 .order("sets.releaseDate DESC")
                 .limit(20)
  end
end
```

### Card Image Helper

```ruby
# app/helpers/cards_helper.rb
module CardsHelper
  SCRYFALL_IMAGE_BASE = "https://cards.scryfall.io"

  # Generate Scryfall image URL from Scryfall ID
  # Format: https://cards.scryfall.io/normal/front/a/b/abc123.jpg
  def card_image_url(card, size: :normal)
    identifier = card.identifiers.find { |i| i.scryfallId.present? }
    return nil unless identifier&.scryfallId

    scryfall_id = identifier.scryfallId
    first = scryfall_id[0]
    second = scryfall_id[1]

    "#{SCRYFALL_IMAGE_BASE}/#{size}/front/#{first}/#{second}/#{scryfall_id}.jpg"
  end

  # Available sizes: small, normal, large, png, art_crop, border_crop
  def card_image_tag(card, size: :normal, **options)
    url = card_image_url(card, size: size)

    if url
      image_tag url,
                alt: "#{card.name} card image",
                loading: "lazy",
                onerror: "this.onerror=null; this.src='#{image_path('card_placeholder.png')}'",
                **options
    else
      content_tag :div, class: "card-image-placeholder #{options[:class]}" do
        content_tag :span, "Image not available"
      end
    end
  end

  # Format mana cost with symbols (basic text version)
  def format_mana_cost(mana_cost)
    return "" if mana_cost.blank?

    # Simple text display: {W}{U}{B}{R}{G} → W U B R G
    # Can be enhanced with mana symbol images later
    mana_cost.gsub(/\{([^}]+)\}/, '<span class="mana-symbol mana-\1">\1</span>').html_safe
  end

  # Format rarity with appropriate styling class
  def rarity_class(rarity)
    case rarity&.downcase
    when "common" then "text-gray-600"
    when "uncommon" then "text-gray-400"
    when "rare" then "text-amber-500"
    when "mythic" then "text-orange-500"
    when "special" then "text-purple-500"
    else "text-gray-600"
    end
  end
end
```

### Views

```
app/views/cards/
├── index.html.erb          # Search (Phase 1.2)
├── show.html.erb           # Card detail page
├── _card_image.html.erb    # Card image partial
├── _legalities.html.erb    # Legalities section
├── _rulings.html.erb       # Rulings section
└── _other_printings.html.erb # Other printings section
```

### Card Detail View Structure

```erb
<%# app/views/cards/show.html.erb %>
<% content_for :title, @card.name %>

<article class="max-w-4xl mx-auto" itemscope itemtype="https://schema.org/Product">
  <nav class="mb-6">
    <%= link_to "← Back", :back, class: "text-indigo-600 hover:text-indigo-800" %>
  </nav>

  <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
    <!-- Card Image -->
    <aside class="md:col-span-1">
      <%= render "card_image", card: @card %>
    </aside>

    <!-- Card Details -->
    <section class="md:col-span-2">
      <header class="mb-6">
        <h1 class="text-3xl font-bold" itemprop="name"><%= @card.name %></h1>
        <p class="text-xl text-gray-600"><%= format_mana_cost(@card.manaCost) %></p>
      </header>

      <dl class="space-y-4">
        <div>
          <dt class="font-semibold text-gray-700">Type</dt>
          <dd><%= @card.type %></dd>
        </div>

        <% if @card.text.present? %>
          <div>
            <dt class="font-semibold text-gray-700">Rules Text</dt>
            <dd class="whitespace-pre-line"><%= @card.text %></dd>
          </div>
        <% end %>

        <% if @card.power.present? && @card.toughness.present? %>
          <div>
            <dt class="font-semibold text-gray-700">Power/Toughness</dt>
            <dd><%= @card.power %>/<%= @card.toughness %></dd>
          </div>
        <% end %>

        <% if @card.loyalty.present? %>
          <div>
            <dt class="font-semibold text-gray-700">Loyalty</dt>
            <dd><%= @card.loyalty %></dd>
          </div>
        <% end %>

        <div>
          <dt class="font-semibold text-gray-700">Set</dt>
          <dd>
            <%= link_to set_path(@card.set.code), class: "text-indigo-600 hover:underline" do %>
              <%= @card.set.name %> (<%= @card.set.code %>)
            <% end %>
          </dd>
        </div>

        <div>
          <dt class="font-semibold text-gray-700">Rarity</dt>
          <dd class="<%= rarity_class(@card.rarity) %>"><%= @card.rarity&.capitalize %></dd>
        </div>

        <% if @card.artist.present? %>
          <div>
            <dt class="font-semibold text-gray-700">Artist</dt>
            <dd><%= @card.artist %></dd>
          </div>
        <% end %>

        <% if @card.number.present? %>
          <div>
            <dt class="font-semibold text-gray-700">Card Number</dt>
            <dd><%= @card.number %></dd>
          </div>
        <% end %>
      </dl>

      <!-- Legalities Section -->
      <%= render "legalities", legalities: @card.legalities.first %>

      <!-- Rulings Section -->
      <% if @card.rulings.any? %>
        <%= render "rulings", rulings: @card.rulings %>
      <% end %>
    </section>
  </div>

  <!-- Other Printings -->
  <% if @other_printings.any? %>
    <%= render "other_printings", printings: @other_printings %>
  <% end %>

  <!-- Action: Add to Collection (Phase 2 hook) -->
  <footer class="mt-8 pt-8 border-t">
    <p class="text-gray-500">
      Want to add this card to your collection?
      <span class="text-indigo-600">Coming soon in Phase 2!</span>
    </p>
  </footer>
</article>
```

### Legalities Model Enhancement

```ruby
# app/models/mtgjson/card_legality.rb
module MTGJSON
  class CardLegality < Base
    # ... existing code ...

    # Major formats to display
    DISPLAY_FORMATS = %w[
      standard
      pioneer
      modern
      legacy
      vintage
      commander
      pauper
      brawl
    ].freeze

    # Get formatted legalities hash
    def format_legalities
      DISPLAY_FORMATS.each_with_object({}) do |format, hash|
        value = send(format) rescue nil
        hash[format] = value if value.present?
      end
    end
  end
end
```

---

## Database Changes

**None required.** This feature uses existing MTGJSON database models.

---

## Test Requirements

### Request Specs

```ruby
# spec/requests/cards_spec.rb (additions)
require "rails_helper"

RSpec.describe "Cards", type: :request do
  describe "GET /cards/:uuid" do
    context "when card exists" do
      let(:card) { MTGJSON::Card.first }

      it "returns successful response" do
        get card_path(card.uuid)
        expect(response).to have_http_status(:ok)
      end

      it "displays card name" do
        get card_path(card.uuid)
        expect(response.body).to include(card.name)
      end

      it "displays card type" do
        get card_path(card.uuid)
        expect(response.body).to include(card.type)
      end

      it "includes set information" do
        get card_path(card.uuid)
        expect(response.body).to include(card.set.name)
      end
    end

    context "when card has legalities" do
      let(:card) { MTGJSON::Card.joins(:legalities).first }

      it "displays legalities section" do
        get card_path(card.uuid)
        expect(response.body).to include("Legalities")
      end
    end

    context "when card has rulings" do
      let(:card) { MTGJSON::Card.joins(:rulings).first }

      it "displays rulings section" do
        get card_path(card.uuid)
        expect(response.body).to include("Rulings")
      end
    end

    context "when card has other printings" do
      let(:card) { MTGJSON::Card.where(name: "Lightning Bolt").first }

      it "displays other printings" do
        get card_path(card.uuid)
        expect(response.body).to include("Other Printings")
      end
    end

    context "when card does not exist" do
      it "redirects with error message" do
        get card_path("invalid-uuid-12345")
        expect(response).to redirect_to(cards_path)
        follow_redirect!
        expect(response.body).to include("Card not found")
      end
    end
  end
end
```

### System Specs

```ruby
# spec/system/card_detail_spec.rb
require "rails_helper"

RSpec.describe "Card Detail", type: :system do
  before do
    driven_by(:selenium_headless)
  end

  let(:card) { MTGJSON::Card.find_by(name: "Lightning Bolt") || MTGJSON::Card.first }

  describe "viewing card details" do
    before { visit card_path(card.uuid) }

    it "displays the card name" do
      expect(page).to have_selector("h1", text: card.name)
    end

    it "displays the card type" do
      expect(page).to have_content(card.type)
    end

    it "displays the mana cost" do
      expect(page).to have_content(card.manaCost) if card.manaCost.present?
    end

    it "displays the set name with link" do
      expect(page).to have_link(card.set.name, href: set_path(card.set.code))
    end

    it "displays the rarity" do
      expect(page).to have_content(card.rarity.capitalize)
    end
  end

  describe "card image" do
    context "when card has Scryfall ID" do
      let(:card_with_image) do
        MTGJSON::Card.joins(:identifiers)
                     .where.not(cardIdentifiers: { scryfallId: nil })
                     .first
      end

      it "displays the card image" do
        visit card_path(card_with_image.uuid)
        expect(page).to have_css("img[alt*='#{card_with_image.name}']")
      end
    end
  end

  describe "format legalities" do
    let(:card_with_legalities) do
      MTGJSON::Card.joins(:legalities).first
    end

    it "displays legalities section" do
      visit card_path(card_with_legalities.uuid)
      expect(page).to have_content("Legalities")
    end

    it "shows format status" do
      visit card_path(card_with_legalities.uuid)
      expect(page).to have_css("[data-testid='legality-item']", minimum: 1)
    end
  end

  describe "rulings" do
    context "when card has rulings" do
      let(:card_with_rulings) do
        MTGJSON::Card.joins(:rulings).first
      end

      it "displays rulings section" do
        visit card_path(card_with_rulings.uuid)
        expect(page).to have_content("Rulings")
      end

      it "shows ruling date and text" do
        visit card_path(card_with_rulings.uuid)
        expect(page).to have_css("[data-testid='ruling-item']", minimum: 1)
      end
    end

    context "when card has no rulings" do
      let(:card_without_rulings) do
        MTGJSON::Card.left_joins(:rulings)
                     .where(cardRulings: { uuid: nil })
                     .first
      end

      it "does not show rulings section" do
        skip "No cards without rulings in test data" unless card_without_rulings
        visit card_path(card_without_rulings.uuid)
        expect(page).not_to have_content("Rulings")
      end
    end
  end

  describe "other printings" do
    context "when card has multiple printings" do
      let(:card_name) { "Lightning Bolt" }
      let(:card) { MTGJSON::Card.find_by(name: card_name) }

      before do
        skip "Lightning Bolt not in test database" unless card
      end

      it "displays other printings section" do
        visit card_path(card.uuid)
        expect(page).to have_content("Other Printings")
      end

      it "links to other printing versions" do
        visit card_path(card.uuid)
        within("[data-testid='other-printings']") do
          expect(page).to have_css("a", minimum: 1)
        end
      end

      it "navigates to other printing" do
        visit card_path(card.uuid)
        first("[data-testid='other-printings'] a").click
        expect(page).to have_current_path(%r{/cards/})
        expect(page).to have_content(card_name)
      end
    end
  end

  describe "navigation" do
    it "has back link" do
      visit card_path(card.uuid)
      expect(page).to have_link("Back")
    end

    it "navigates to set page" do
      visit card_path(card.uuid)
      click_link card.set.name
      expect(page).to have_current_path(set_path(card.set.code))
    end
  end

  describe "creature cards" do
    let(:creature) do
      MTGJSON::Card.where("type LIKE ?", "%Creature%")
                   .where.not(power: nil)
                   .first
    end

    it "displays power and toughness" do
      visit card_path(creature.uuid)
      expect(page).to have_content("#{creature.power}/#{creature.toughness}")
    end
  end

  describe "planeswalker cards" do
    let(:planeswalker) do
      MTGJSON::Card.where("type LIKE ?", "%Planeswalker%")
                   .where.not(loyalty: nil)
                   .first
    end

    it "displays loyalty" do
      skip "No planeswalker in test data" unless planeswalker
      visit card_path(planeswalker.uuid)
      expect(page).to have_content("Loyalty")
      expect(page).to have_content(planeswalker.loyalty)
    end
  end
end
```

### Helper Specs

```ruby
# spec/helpers/cards_helper_spec.rb
require "rails_helper"

RSpec.describe CardsHelper, type: :helper do
  describe "#card_image_url" do
    let(:card) { MTGJSON::Card.joins(:identifiers).first }

    context "when card has Scryfall ID" do
      it "returns Scryfall CDN URL" do
        url = helper.card_image_url(card)
        expect(url).to start_with("https://cards.scryfall.io")
        expect(url).to end_with(".jpg")
      end

      it "accepts size parameter" do
        url = helper.card_image_url(card, size: :large)
        expect(url).to include("/large/")
      end
    end

    context "when card has no Scryfall ID" do
      let(:card_without_id) do
        MTGJSON::Card.left_joins(:identifiers)
                     .where(cardIdentifiers: { scryfallId: nil })
                     .first
      end

      it "returns nil" do
        skip "All cards have Scryfall IDs" unless card_without_id
        expect(helper.card_image_url(card_without_id)).to be_nil
      end
    end
  end

  describe "#format_mana_cost" do
    it "formats mana symbols" do
      result = helper.format_mana_cost("{R}")
      expect(result).to include("mana-symbol")
    end

    it "handles multiple symbols" do
      result = helper.format_mana_cost("{2}{R}{R}")
      expect(result.scan("mana-symbol").count).to eq(3)
    end

    it "returns empty string for nil" do
      expect(helper.format_mana_cost(nil)).to eq("")
    end
  end

  describe "#rarity_class" do
    it "returns gray for common" do
      expect(helper.rarity_class("common")).to include("gray")
    end

    it "returns amber for rare" do
      expect(helper.rarity_class("rare")).to include("amber")
    end

    it "returns orange for mythic" do
      expect(helper.rarity_class("mythic")).to include("orange")
    end

    it "handles case insensitivity" do
      expect(helper.rarity_class("RARE")).to include("amber")
    end
  end
end
```

### View Specs

```ruby
# spec/views/cards/show.html.erb_spec.rb
require "rails_helper"

RSpec.describe "cards/show", type: :view do
  let(:card) { MTGJSON::Card.includes(:set, :legalities, :rulings, :identifiers).first }

  before do
    assign(:card, card)
    assign(:other_printings, [])
  end

  it "renders card name as heading" do
    render
    expect(rendered).to have_selector("h1", text: card.name)
  end

  it "renders card type" do
    render
    expect(rendered).to include(card.type)
  end

  it "renders set information" do
    render
    expect(rendered).to include(card.set.name)
  end

  it "renders rarity" do
    render
    expect(rendered).to include(card.rarity.capitalize)
  end

  context "with rules text" do
    let(:card) { MTGJSON::Card.where.not(text: nil).first }

    it "renders rules text" do
      assign(:card, card)
      render
      expect(rendered).to include(card.text.split("\n").first)
    end
  end

  context "with other printings" do
    let(:printings) { MTGJSON::Card.where(name: card.name).where.not(uuid: card.uuid).limit(3) }

    before { assign(:other_printings, printings) }

    it "renders other printings section" do
      render
      expect(rendered).to include("Other Printings")
    end
  end
end
```

---

## UI/UX Specifications

### Card Detail Layout

```
┌─────────────────────────────────────────────────────────────┐
│ ← Back                                                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐   Lightning Bolt                          │
│  │             │   {R}                                      │
│  │   [CARD     │                                            │
│  │   IMAGE]    │   Type: Instant                            │
│  │             │                                            │
│  │             │   Lightning Bolt deals 3 damage to any     │
│  │             │   target.                                  │
│  │             │                                            │
│  └─────────────┘   Set: Limited Edition Alpha (LEA)        │
│                    Rarity: Common                           │
│                    Artist: Christopher Rush                 │
│                    Number: 161                              │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Legalities                                                  │
│ ┌────────────┬────────────┬────────────┬────────────┐       │
│ │ Modern     │ Legacy     │ Vintage    │ Commander  │       │
│ │ ✓ Legal    │ ✓ Legal    │ ✓ Legal    │ ✓ Legal    │       │
│ └────────────┴────────────┴────────────┴────────────┘       │
│ ┌────────────┬────────────┬────────────┬────────────┐       │
│ │ Pioneer    │ Standard   │ Pauper     │ Brawl      │       │
│ │ ✗ Not Legal│ ✗ Not Legal│ ✓ Legal    │ ✗ Not Legal│       │
│ └────────────┴────────────┴────────────┴────────────┘       │
├─────────────────────────────────────────────────────────────┤
│ Rulings                                                     │
│                                                             │
│ 2004-10-04                                                  │
│ The damage can be dealt to any target, including players    │
│ and planeswalkers.                                          │
│                                                             │
│ 2009-10-01                                                  │
│ If the target is an illegal target when this spell tries    │
│ to resolve, the spell won't resolve and none of its effects │
│ will happen.                                                │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Other Printings (30+)                                       │
│                                                             │
│ MH2 Modern Horizons 2 · 4ED Fourth Edition · 3ED Revised    │
│ 2ED Unlimited Edition · LEA Limited Edition Alpha · ...     │
│ [View all printings →]                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Legality Badge Styles

```
✓ Legal      - Green background, green text
✗ Not Legal  - Gray background, gray text
⊘ Banned     - Red background, red text
⚠ Restricted - Yellow background, yellow text
```

### Responsive Design

- **Mobile**: Card image stacked above details
- **Tablet/Desktop**: Card image on left, details on right
- Legalities displayed in 2x4 grid on mobile, 4x2 on desktop

---

## Scryfall Image Integration

### Image URL Format

```
https://cards.scryfall.io/{size}/front/{first}/{second}/{scryfallId}.jpg
```

**Available sizes:**
- `small` - 146×204 (thumbnail)
- `normal` - 488×680 (default)
- `large` - 672×936 (high quality)
- `png` - 745×1040 (transparent, slow)
- `art_crop` - Cropped to art only
- `border_crop` - Full card without border

### Image Caching

Consider using Rails Active Storage or a CDN proxy for:
- Reducing Scryfall API load
- Faster repeat views
- Offline capability

**Note**: This is a future enhancement, not MVP requirement.

---

## Accessibility

- Card image has descriptive alt text
- Headings used correctly (h1 for card name)
- Color is not the only indicator (icons + text for legalities)
- All interactive elements are keyboard accessible
- ARIA labels for icon-only buttons
- Schema.org markup for SEO

---

## Dependencies

- **Phase 1.1**: Set Browser (set links)
- **Phase 1.2**: Card Search (search navigation)
- **Scryfall CDN**: External service for card images (graceful degradation if unavailable)

---

## Definition of Done

- [ ] `CardsController#show` action implemented
- [ ] Route configured for `/cards/:uuid`
- [ ] Card detail page displays all basic info (name, type, cost, text, etc.)
- [ ] Card image displayed from Scryfall CDN
- [ ] Image placeholder shown when image unavailable
- [ ] Legalities section displays major format statuses
- [ ] Rulings section displays when card has rulings
- [ ] Other printings section displays when card has multiple printings
- [ ] Navigation to set page works
- [ ] Back navigation works
- [ ] Links to other printings work
- [ ] Creature power/toughness displayed
- [ ] Planeswalker loyalty displayed
- [ ] All request specs pass
- [ ] All system specs pass
- [ ] All helper specs pass
- [ ] Responsive design works on mobile
- [ ] Accessible (proper headings, alt text, ARIA)
- [ ] `bin/rubocop --fix` passes
- [ ] `bin/rspec` passes

---

## Future Enhancements (Not in MVP)

- High-resolution image modal/zoom
- Double-faced card support (flip/toggle)
- Mana symbol images (instead of text)
- Price display (Phase 4)
- "Add to Collection" button (Phase 2)
- Share card link
- Print-friendly view
- Keyboard shortcuts
- Flavor text display
- Card frame/border styling based on color
