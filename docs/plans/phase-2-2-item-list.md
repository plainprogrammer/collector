# Phase 2.2: Item List View

## Feature Overview

Display all items in a collection as a browsable list, showing key card information and item attributes. This view serves as the primary interface for viewing and managing a collection's contents.

**Priority**: Critical (core MVP functionality)
**Dependencies**: Phase 2.1 (Add Item to Collection)
**Estimated Complexity**: Medium

---

## User Stories

### US-2.2.1: View Collection Items
**As a** collector
**I want to** see all items in my collection
**So that** I can browse what I own

### US-2.2.2: See Card Information
**As a** collector
**I want to** see card name, set, and type for each item
**So that** I can identify cards at a glance

### US-2.2.3: See Item Attributes
**As a** collector
**I want to** see condition, finish, and storage location
**So that** I can understand each item's details

### US-2.2.4: Visual Distinction for Special Items
**As a** collector
**I want to** quickly identify foils, signed, and altered cards
**So that** I can find special items easily

### US-2.2.5: Navigate to Item Details
**As a** collector
**I want to** click an item to view full details
**So that** I can see all information about that item

### US-2.2.6: Paginate Large Collections
**As a** collector
**I want to** browse through pages of items
**So that** large collections load quickly

---

## Acceptance Criteria

### AC-2.2.1: Items Index Page

```gherkin
Feature: Items Index Page

  Scenario: View items in a collection
    Given my collection "Main" has 10 items
    When I visit the collection items page
    Then I should see all 10 items
    And each item should display:
      | field          | example                    |
      | card name      | "Lightning Bolt"           |
      | set code       | "LEA"                      |
      | set name       | "Limited Edition Alpha"    |
      | condition      | "Near Mint"                |
      | finish         | "Non-foil"                 |
      | storage unit   | "Box A" or "Loose"         |

  Scenario: Empty collection
    Given my collection "Empty" has no items
    When I visit the collection items page
    Then I should see "No items in this collection"
    And I should see a call-to-action to add cards
    And I should see a link to the card search

  Scenario: Access from collection show page
    Given I am on my collection's page
    When I click "View Items" or navigate to items
    Then I should see the items list
```

### AC-2.2.2: Item Card Display

```gherkin
Feature: Item Card Display

  Scenario: Display card thumbnail
    Given an item for "Lightning Bolt" exists
    When I view the items list
    Then I should see a thumbnail of the card image
    And the thumbnail should link to the item detail page

  Scenario: Display card name with link
    Given an item exists in my collection
    When I view the items list
    Then the card name should link to the card detail page
    And clicking it should open the MTGJSON card view

  Scenario: Display type line
    Given an item for a creature card exists
    When I view the items list
    Then I should see the card's type (e.g., "Creature - Human Wizard")
```

### AC-2.2.3: Item Attributes Display

```gherkin
Feature: Item Attributes Display

  Scenario: Display condition with abbreviation
    Given an item with condition "lightly_played" exists
    When I view the items list
    Then I should see "LP" or "Lightly Played"

  Scenario: Display finish
    Given a foil item exists
    When I view the items list
    Then I should see "Foil" or a foil indicator

  Scenario: Display storage location
    Given an item stored in "Deck Box Alpha" exists
    When I view the items list
    Then I should see "Deck Box Alpha"

  Scenario: Display loose items
    Given an item with no storage unit exists
    When I view the items list
    Then I should see "Loose" or no location displayed

  Scenario: Display language for non-English cards
    Given an item with language "ja" exists
    When I view the items list
    Then I should see "Japanese" or "JA" indicator
```

### AC-2.2.4: Visual Distinction for Special Items

```gherkin
Feature: Special Item Indicators

  Scenario: Foil indicator
    Given a foil item exists
    When I view the items list
    Then the item should have a foil badge or icon
    And the styling should be distinct from non-foil items

  Scenario: Signed indicator
    Given a signed item exists
    When I view the items list
    Then I should see a "Signed" badge or icon

  Scenario: Altered indicator
    Given an altered item exists
    When I view the items list
    Then I should see an "Altered" badge or icon

  Scenario: Misprint indicator
    Given a misprint item exists
    When I view the items list
    Then I should see a "Misprint" badge or icon

  Scenario: Multiple special attributes
    Given an item is both foil and signed
    When I view the items list
    Then I should see both foil and signed indicators
```

### AC-2.2.5: Item Count and Summary

```gherkin
Feature: Collection Summary

  Scenario: Display item count
    Given my collection has 47 items
    When I visit the items list
    Then I should see "47 items" in the header

  Scenario: Display value summary (if prices available)
    Given my collection has items with known prices
    When I visit the items list
    Then I should see total estimated value
    (Note: Full implementation in Phase 4)
```

### AC-2.2.6: Pagination

```gherkin
Feature: Items Pagination

  Scenario: Paginate large collections
    Given my collection has 100 items
    And pagination is set to 24 per page
    When I visit the items list
    Then I should see 24 items
    And I should see pagination controls

  Scenario: Navigate between pages
    Given I am on page 1 of items
    When I click "Next"
    Then I should see items 25-48
    And the URL should include "page=2"

  Scenario: Last page
    Given I am on the last page
    Then the "Next" link should be disabled
```

### AC-2.2.7: Navigation

```gherkin
Feature: Items Navigation

  Scenario: Navigate to item detail
    Given I see an item in the list
    When I click on the item row
    Then I should be on the item detail page

  Scenario: Navigate to card detail
    Given I see an item in the list
    When I click on the card name link
    Then I should be on the MTGJSON card detail page

  Scenario: Add new item
    Given I am on the items list
    When I click "Add Card"
    Then I should be on the card search page

  Scenario: Back to collection
    Given I am on the items list
    When I click the collection name or back link
    Then I should be on the collection show page
```

---

## Technical Implementation

### Routes

```ruby
# config/routes.rb
# Simplified: Items nested under collections with shallow routing
resources :collections do
  resources :items, shallow: true
  resources :storage_units, shallow: true
end
```

**Routes for this feature:**
- `GET /collections/:collection_id/items` → `items#index`

### Controller

```ruby
# app/controllers/items_controller.rb
class ItemsController < ApplicationController
  before_action :set_collection, only: [:index]
  before_action :set_item, only: [:show, :edit, :update, :destroy]

  def index
    @items = @collection.items
                        .includes(:storage_unit)
                        .order(created_at: :desc)
                        .page(params[:page])
                        .per(24)

    # Batch load MTGJSON card data to avoid N+1
    @cards = load_cards_for_items(@items)
  end

  private

  def set_collection
    @collection = Collection.find(params[:collection_id])
  end

  def load_cards_for_items(items)
    uuids = items.map(&:card_uuid).uniq
    MTGJSON::Card.includes(:set, :identifiers)
                 .where(uuid: uuids)
                 .index_by(&:uuid)
  end
end
```

### View Helpers

```ruby
# app/helpers/items_helper.rb (additions)
module ItemsHelper
  def condition_badge_class(condition)
    case condition
    when "near_mint" then "bg-green-100 text-green-800"
    when "lightly_played" then "bg-yellow-100 text-yellow-800"
    when "moderately_played" then "bg-orange-100 text-orange-800"
    when "heavily_played" then "bg-red-100 text-red-800"
    when "damaged" then "bg-gray-100 text-gray-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  def condition_abbreviation(condition)
    {
      "near_mint" => "NM",
      "lightly_played" => "LP",
      "moderately_played" => "MP",
      "heavily_played" => "HP",
      "damaged" => "D"
    }[condition] || condition.upcase
  end

  def finish_badge_class(finish)
    case finish
    when "traditional_foil", "etched", "textured", "surge_foil"
      "bg-gradient-to-r from-purple-400 to-pink-400 text-white"
    when "glossy"
      "bg-blue-100 text-blue-800"
    else
      "" # No special styling for non-foil
    end
  end

  def foil?(item)
    %w[traditional_foil etched textured surge_foil glossy].include?(item.finish)
  end

  def special_attributes(item)
    attrs = []
    attrs << "Signed" if item.signed
    attrs << "Altered" if item.altered
    attrs << "Misprint" if item.misprint
    attrs
  end
end
```

### Views

```
app/views/items/
├── index.html.erb          # Items list
├── _item_card.html.erb     # Item card partial for grid view
├── _item_row.html.erb      # Item row partial for table view
├── _empty_state.html.erb   # Empty collection state
└── _filters.html.erb       # Filters (Phase 3)
```

### Items Index View

```erb
<%# app/views/items/index.html.erb %>
<% content_for :title, "#{@collection.name} - Items" %>

<section class="w-full" aria-labelledby="items-heading">
  <header class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
    <div>
      <nav class="text-sm text-gray-500 mb-2">
        <%= link_to "Collections", collections_path %> /
        <%= link_to @collection.name, @collection %>
      </nav>
      <h1 id="items-heading" class="text-3xl font-bold text-gray-900">
        Items
      </h1>
      <p class="mt-1 text-gray-600">
        <%= pluralize(@collection.items.count, "item") %> in this collection
      </p>
    </div>

    <%= link_to cards_path,
        class: "inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors" do %>
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
      </svg>
      Add Card
    <% end %>
  </header>

  <%= turbo_frame_tag "flash" do %>
    <%= render "shared/flash" %>
  <% end %>

  <% if @items.any? %>
    <div id="items" class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      <% @items.each do |item| %>
        <%= render "item_card", item: item, card: @cards[item.card_uuid] %>
      <% end %>
    </div>

    <nav class="mt-8" aria-label="Items pagination">
      <%= paginate @items %>
    </nav>
  <% else %>
    <%= render "empty_state", collection: @collection %>
  <% end %>
</section>
```

### Item Card Partial

```erb
<%# app/views/items/_item_card.html.erb %>
<%= link_to item_path(item),
    class: "block bg-white rounded-lg shadow-sm border hover:shadow-md transition-shadow",
    data: { testid: "item-card" } do %>
  <div class="flex gap-4 p-4">
    <!-- Card Thumbnail -->
    <div class="flex-shrink-0 w-16">
      <% if card %>
        <%= card_image_tag(card, size: :small, class: "w-full rounded") %>
      <% else %>
        <div class="w-full aspect-[5/7] bg-gray-200 rounded"></div>
      <% end %>
    </div>

    <!-- Item Details -->
    <div class="flex-1 min-w-0">
      <h3 class="font-semibold text-gray-900 truncate" data-testid="card-name">
        <%= card&.name || "Unknown Card" %>
      </h3>

      <p class="text-sm text-gray-600 truncate">
        <%= card&.set&.name %> (<%= card&.setCode %>)
      </p>

      <p class="text-xs text-gray-500 truncate mt-1">
        <%= card&.type %>
      </p>

      <!-- Badges -->
      <div class="flex flex-wrap gap-1 mt-2">
        <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium <%= condition_badge_class(item.condition) %>">
          <%= condition_abbreviation(item.condition) %>
        </span>

        <% if foil?(item) %>
          <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium <%= finish_badge_class(item.finish) %>">
            <%= item.finish.humanize %>
          </span>
        <% end %>

        <% if item.language != "en" %>
          <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
            <%= language_name(item.language) %>
          </span>
        <% end %>

        <% special_attributes(item).each do |attr| %>
          <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-800">
            <%= attr %>
          </span>
        <% end %>
      </div>

      <!-- Storage Location -->
      <p class="text-xs text-gray-400 mt-2">
        <% if item.storage_unit %>
          📦 <%= item.storage_unit.name %>
        <% else %>
          📦 Loose
        <% end %>
      </p>
    </div>
  </div>
<% end %>
```

---

## Database Changes

**None required.** Uses existing models and associations.

### Performance Considerations

Add a database index if not already present:

```ruby
# Already exists in schema
t.index ["collection_id", "card_uuid"], name: "index_items_on_collection_id_and_card_uuid"
t.index ["collection_id"], name: "index_items_on_collection_id"
```

Consider adding:
```ruby
t.index ["collection_id", "created_at"], name: "index_items_on_collection_id_and_created_at"
```

---

## Test Requirements

### Request Specs

```ruby
# spec/requests/items_spec.rb (additions)
require "rails_helper"

RSpec.describe "Items", type: :request do
  let(:collection) { create(:collection) }
  let(:card) { MTGJSON::Card.first }

  describe "GET /collections/:collection_id/items" do
    context "with items" do
      before do
        create_list(:item, 5, collection: collection, card_uuid: card.uuid)
      end

      it "returns successful response" do
        get collection_items_path(collection)
        expect(response).to have_http_status(:ok)
      end

      it "displays item count" do
        get collection_items_path(collection)
        expect(response.body).to include("5 items")
      end

      it "displays card names" do
        get collection_items_path(collection)
        expect(response.body).to include(card.name)
      end
    end

    context "with empty collection" do
      it "shows empty state" do
        get collection_items_path(collection)
        expect(response.body).to include("No items")
      end

      it "shows link to add cards" do
        get collection_items_path(collection)
        expect(response.body).to include("Add Card")
      end
    end

    context "with pagination" do
      before do
        create_list(:item, 30, collection: collection, card_uuid: card.uuid)
      end

      it "paginates results" do
        get collection_items_path(collection)
        expect(response.body).to have_css("[data-testid='item-card']", count: 24)
      end

      it "shows pagination controls" do
        get collection_items_path(collection)
        expect(response.body).to include("pagination")
      end

      it "navigates to next page" do
        get collection_items_path(collection, page: 2)
        expect(response).to have_http_status(:ok)
      end
    end

    context "with special items" do
      it "shows foil badge" do
        create(:item, collection: collection, card_uuid: card.uuid, finish: :traditional_foil)
        get collection_items_path(collection)
        expect(response.body).to include("Traditional")
      end

      it "shows signed badge" do
        create(:item, collection: collection, card_uuid: card.uuid, signed: true)
        get collection_items_path(collection)
        expect(response.body).to include("Signed")
      end
    end

    context "when collection not found" do
      it "returns 404" do
        get collection_items_path(id: 99999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
```

### System Specs

```ruby
# spec/system/item_list_spec.rb
require "rails_helper"

RSpec.describe "Item List", type: :system do
  before do
    driven_by(:selenium_headless)
  end

  let(:collection) { create(:collection, name: "My Collection") }
  let(:card) { MTGJSON::Card.first }

  describe "viewing items" do
    context "with items in collection" do
      let!(:item) do
        create(:item,
          collection: collection,
          card_uuid: card.uuid,
          condition: :near_mint,
          finish: :nonfoil
        )
      end

      it "displays items list" do
        visit collection_items_path(collection)

        expect(page).to have_css("[data-testid='item-card']", count: 1)
      end

      it "shows card name" do
        visit collection_items_path(collection)

        expect(page).to have_content(card.name)
      end

      it "shows condition badge" do
        visit collection_items_path(collection)

        expect(page).to have_content("NM")
      end

      it "shows collection name in breadcrumb" do
        visit collection_items_path(collection)

        expect(page).to have_link("My Collection")
      end

      it "shows item count" do
        visit collection_items_path(collection)

        expect(page).to have_content("1 item")
      end
    end

    context "with foil items" do
      let!(:foil_item) do
        create(:item,
          collection: collection,
          card_uuid: card.uuid,
          finish: :traditional_foil
        )
      end

      it "displays foil badge" do
        visit collection_items_path(collection)

        expect(page).to have_content("Traditional Foil")
      end
    end

    context "with signed items" do
      let!(:signed_item) do
        create(:item,
          collection: collection,
          card_uuid: card.uuid,
          signed: true
        )
      end

      it "displays signed badge" do
        visit collection_items_path(collection)

        expect(page).to have_content("Signed")
      end
    end

    context "with storage unit" do
      let(:storage_unit) { create(:storage_unit, collection: collection, name: "Box A") }
      let!(:item) do
        create(:item,
          collection: collection,
          card_uuid: card.uuid,
          storage_unit: storage_unit
        )
      end

      it "displays storage location" do
        visit collection_items_path(collection)

        expect(page).to have_content("Box A")
      end
    end

    context "with loose items" do
      let!(:item) do
        create(:item,
          collection: collection,
          card_uuid: card.uuid,
          storage_unit: nil
        )
      end

      it "displays 'Loose'" do
        visit collection_items_path(collection)

        expect(page).to have_content("Loose")
      end
    end

    context "with non-English items" do
      let!(:item) do
        create(:item,
          collection: collection,
          card_uuid: card.uuid,
          language: "ja"
        )
      end

      it "displays language indicator" do
        visit collection_items_path(collection)

        expect(page).to have_content("Japanese")
      end
    end
  end

  describe "empty collection" do
    it "shows empty state message" do
      visit collection_items_path(collection)

      expect(page).to have_content("No items in this collection")
    end

    it "shows add card button" do
      visit collection_items_path(collection)

      expect(page).to have_link("Add Card", href: cards_path)
    end
  end

  describe "navigation" do
    let!(:item) do
      create(:item, collection: collection, card_uuid: card.uuid)
    end

    it "navigates to item detail on click" do
      visit collection_items_path(collection)

      click_link href: item_path(item)

      expect(page).to have_current_path(item_path(item))
    end

    it "navigates to card detail from card name" do
      visit collection_items_path(collection)

      # If card name is a separate link
      # click_link card.name
      # expect(page).to have_current_path(card_path(card.uuid))
    end

    it "navigates to add card" do
      visit collection_items_path(collection)

      click_link "Add Card"

      expect(page).to have_current_path(cards_path)
    end

    it "navigates back to collection" do
      visit collection_items_path(collection)

      click_link "My Collection"

      expect(page).to have_current_path(collection_path(collection))
    end
  end

  describe "pagination" do
    before do
      create_list(:item, 30, collection: collection, card_uuid: card.uuid)
    end

    it "shows first page" do
      visit collection_items_path(collection)

      expect(page).to have_css("[data-testid='item-card']", count: 24)
    end

    it "navigates to next page" do
      visit collection_items_path(collection)

      click_link "Next"

      expect(page).to have_current_path(/page=2/)
      expect(page).to have_css("[data-testid='item-card']", count: 6)
    end
  end
end
```

### Helper Specs

```ruby
# spec/helpers/items_helper_spec.rb (additions)
require "rails_helper"

RSpec.describe ItemsHelper, type: :helper do
  describe "#condition_badge_class" do
    it "returns green for near_mint" do
      expect(helper.condition_badge_class("near_mint")).to include("green")
    end

    it "returns yellow for lightly_played" do
      expect(helper.condition_badge_class("lightly_played")).to include("yellow")
    end

    it "returns red for heavily_played" do
      expect(helper.condition_badge_class("heavily_played")).to include("red")
    end
  end

  describe "#condition_abbreviation" do
    it "returns NM for near_mint" do
      expect(helper.condition_abbreviation("near_mint")).to eq("NM")
    end

    it "returns LP for lightly_played" do
      expect(helper.condition_abbreviation("lightly_played")).to eq("LP")
    end
  end

  describe "#foil?" do
    it "returns true for traditional_foil" do
      item = build(:item, finish: :traditional_foil)
      expect(helper.foil?(item)).to be true
    end

    it "returns false for nonfoil" do
      item = build(:item, finish: :nonfoil)
      expect(helper.foil?(item)).to be false
    end
  end

  describe "#special_attributes" do
    it "returns signed when signed" do
      item = build(:item, signed: true)
      expect(helper.special_attributes(item)).to include("Signed")
    end

    it "returns multiple attributes" do
      item = build(:item, signed: true, altered: true, misprint: true)
      attrs = helper.special_attributes(item)
      expect(attrs).to include("Signed", "Altered", "Misprint")
    end

    it "returns empty array when no special attributes" do
      item = build(:item, signed: false, altered: false, misprint: false)
      expect(helper.special_attributes(item)).to be_empty
    end
  end
end
```

---

## UI/UX Specifications

### Items Grid Layout

```
┌─────────────────────────────────────────────────────────────┐
│ Collections / My Collection                                 │
│                                                             │
│ Items                                        [ Add Card ]   │
│ 47 items in this collection                                 │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ │
│ │ ┌───┐           │ │ ┌───┐           │ │ ┌───┐           │ │
│ │ │IMG│ Lightning │ │ │IMG│ Serra     │ │ │IMG│ Black     │ │
│ │ │   │ Bolt      │ │ │   │ Angel     │ │ │   │ Lotus     │ │
│ │ └───┘ LEA       │ │ └───┘ LEA       │ │ └───┘ LEA       │ │
│ │       Instant   │ │       Creature  │ │       Artifact  │ │
│ │                 │ │                 │ │                 │ │
│ │ [NM] [Foil]     │ │ [LP]            │ │ [NM] [Signed]   │ │
│ │ 📦 Box A        │ │ 📦 Loose        │ │ 📦 Display Case │ │
│ └─────────────────┘ └─────────────────┘ └─────────────────┘ │
│                                                             │
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ │
│ │ ...             │ │ ...             │ │ ...             │ │
│ └─────────────────┘ └─────────────────┘ └─────────────────┘ │
│                                                             │
│            « Previous   1  2  3  ...  Next »                │
└─────────────────────────────────────────────────────────────┘
```

### Empty State

```
┌─────────────────────────────────────────────────────────────┐
│ Collections / My Collection                                 │
│                                                             │
│ Items                                        [ Add Card ]   │
│ 0 items in this collection                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                       📦                                     │
│                                                             │
│              No items in this collection                    │
│                                                             │
│         Start by searching for cards to add.                │
│                                                             │
│                    [ Search Cards ]                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Condition Badge Colors

| Condition | Color | Class |
|-----------|-------|-------|
| Near Mint | Green | `bg-green-100 text-green-800` |
| Lightly Played | Yellow | `bg-yellow-100 text-yellow-800` |
| Moderately Played | Orange | `bg-orange-100 text-orange-800` |
| Heavily Played | Red | `bg-red-100 text-red-800` |
| Damaged | Gray | `bg-gray-100 text-gray-800` |

### Finish Badge Styling

| Finish | Style |
|--------|-------|
| Non-foil | No badge (default) |
| Traditional Foil | Gradient purple-pink |
| Etched | Gradient purple-pink |
| Surge Foil | Gradient purple-pink |
| Textured | Gradient purple-pink |
| Glossy | Blue badge |

---

## Dependencies

- **Phase 2.1**: Add Item (items must exist)
- **Phase 1.3**: Card Detail (for card images and helpers)
- **Kaminari**: For pagination

---

## Definition of Done

- [ ] `ItemsController#index` action implemented
- [ ] Route configured for `/collections/:collection_id/items`
- [ ] Items grid displays all items in collection
- [ ] Card thumbnail displayed (from Scryfall)
- [ ] Card name, set, type displayed
- [ ] Condition badge with abbreviation
- [ ] Finish badge for foil cards
- [ ] Language indicator for non-English cards
- [ ] Special attribute badges (signed, altered, misprint)
- [ ] Storage location displayed
- [ ] Item count in header
- [ ] Empty state with call-to-action
- [ ] Pagination works (24 per page)
- [ ] Click item navigates to detail
- [ ] "Add Card" button navigates to search
- [ ] Breadcrumb navigation works
- [ ] N+1 queries prevented (batch loading)
- [ ] All request specs pass
- [ ] All system specs pass
- [ ] All helper specs pass
- [ ] Responsive design (1-4 columns)
- [ ] Accessible (keyboard, screen reader)
- [ ] `bin/rubocop --fix` passes
- [ ] `bin/rspec` passes

---

## Future Enhancements (Not in MVP)

- Toggle between grid and table view
- Sorting options (name, date added, value)
- Filtering (Phase 3)
- Bulk selection
- Quick actions (edit, delete from list)
- Card image hover preview
- Infinite scroll alternative to pagination
- Value display per item (Phase 4)
