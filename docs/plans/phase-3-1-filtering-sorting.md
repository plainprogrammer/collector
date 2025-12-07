# Phase 3.1: Collection Filtering & Sorting

## Feature Overview

Enable users to filter and sort items within a collection to quickly find specific cards. This feature transforms the item list from a simple inventory view into a powerful search and navigation tool.

**Priority**: High (essential for usability with larger collections)
**Dependencies**: Phase 2.2 (Item List View)
**Estimated Complexity**: Medium-High

---

## User Stories

### US-3.1.1: Filter by Set
**As a** collector
**I want to** filter my collection items by set
**So that** I can see all cards from a specific set I own

### US-3.1.2: Filter by Color
**As a** collector
**I want to** filter items by card color/color identity
**So that** I can find cards for deck building by color

### US-3.1.3: Filter by Card Type
**As a** collector
**I want to** filter items by card type (creature, instant, etc.)
**So that** I can find specific types of cards

### US-3.1.4: Filter by Condition
**As a** collector
**I want to** filter items by condition
**So that** I can see my mint vs played cards

### US-3.1.5: Filter by Finish
**As a** collector
**I want to** filter items by finish (foil vs non-foil)
**So that** I can see my special variants

### US-3.1.6: Sort Items
**As a** collector
**I want to** sort items by different criteria
**So that** I can organize my view by what matters to me

### US-3.1.7: Combine Filters
**As a** collector
**I want to** combine multiple filters
**So that** I can narrow down to very specific cards

### US-3.1.8: Preserve Filter State
**As a** collector
**I want to** share filtered views via URL
**So that** I can bookmark specific views or share with others

---

## Acceptance Criteria

### AC-3.1.1: Filter Controls UI

```gherkin
Feature: Filter Controls Display

  Scenario: Filter controls visible on items index
    Given I am viewing a collection's items
    Then I should see a filter/sort control area
    And I should see filter options for:
      | filter     |
      | Set        |
      | Color      |
      | Type       |
      | Condition  |
      | Finish     |
    And I should see sort options

  Scenario: Filter controls collapsed on mobile
    Given I am viewing on a mobile device
    Then the filter controls should be collapsed by default
    And I should see a "Filters" button to expand them
```

### AC-3.1.2: Set Filter

```gherkin
Feature: Filter by Set

  Scenario: Set dropdown shows sets in collection
    Given my collection has items from sets "MH3", "ONE", and "BRO"
    When I view the set filter dropdown
    Then I should see options for "MH3", "ONE", and "BRO"
    And I should not see sets I don't own cards from

  Scenario: Filter by single set
    Given my collection has 10 items from "MH3" and 5 from "ONE"
    When I select "MH3" from the set filter
    Then I should see 10 items
    And all items should be from set "MH3"

  Scenario: Clear set filter
    Given I have filtered by set "MH3"
    When I select "All Sets" or clear the filter
    Then I should see all items in the collection
```

### AC-3.1.3: Color Filter

```gherkin
Feature: Filter by Color

  Scenario: Color filter options
    When I view the color filter
    Then I should see options for:
      | color      | symbol |
      | White      | W      |
      | Blue       | U      |
      | Black      | B      |
      | Red        | R      |
      | Green      | G      |
      | Colorless  | C      |
      | Multicolor | M      |

  Scenario: Filter by single color
    Given my collection has red and blue cards
    When I select "Red" from the color filter
    Then I should see only cards that contain red in their color identity

  Scenario: Filter by colorless
    Given my collection has artifacts and lands
    When I select "Colorless"
    Then I should see cards with no colors

  Scenario: Filter by multicolor
    Given my collection has multicolor cards
    When I select "Multicolor"
    Then I should see cards with 2+ colors
```

### AC-3.1.4: Type Filter

```gherkin
Feature: Filter by Card Type

  Scenario: Type filter options
    When I view the type filter
    Then I should see options including:
      | type         |
      | Creature     |
      | Instant      |
      | Sorcery      |
      | Artifact     |
      | Enchantment  |
      | Planeswalker |
      | Land         |

  Scenario: Filter by type
    Given my collection has creatures and instants
    When I select "Creature" from the type filter
    Then I should see only creature cards
    And creatures with additional types (e.g., "Artifact Creature") should be included
```

### AC-3.1.5: Condition Filter

```gherkin
Feature: Filter by Condition

  Scenario: Condition filter options
    When I view the condition filter
    Then I should see options for:
      | condition         |
      | Near Mint (NM)    |
      | Lightly Played    |
      | Moderately Played |
      | Heavily Played    |
      | Damaged           |

  Scenario: Filter by condition
    Given my collection has NM and LP cards
    When I select "Near Mint (NM)"
    Then I should see only items with near_mint condition

  Scenario: Filter shows item attributes not card attributes
    Given I have two copies of the same card
    And one is NM and one is LP
    When I filter by "Lightly Played"
    Then I should see only the LP copy
```

### AC-3.1.6: Finish Filter

```gherkin
Feature: Filter by Finish

  Scenario: Finish filter options
    When I view the finish filter
    Then I should see options for:
      | finish           |
      | Non-foil         |
      | Any Foil         |
      | Traditional Foil |
      | Etched           |
      | Other Special    |

  Scenario: Filter by foil
    Given my collection has foil and non-foil cards
    When I select "Any Foil"
    Then I should see items with traditional_foil, etched, glossy, textured, or surge_foil finish

  Scenario: Filter by specific foil type
    When I select "Etched"
    Then I should see only items with etched finish
```

### AC-3.1.7: Sorting

```gherkin
Feature: Sort Items

  Scenario: Sort options available
    When I view the sort options
    Then I should see:
      | sort option    | direction |
      | Name           | A-Z, Z-A  |
      | Set            | A-Z, Z-A  |
      | Date Added     | Newest, Oldest |
      | Condition      | Best, Worst |
      | Mana Value     | Low, High |

  Scenario: Sort by name ascending
    When I select sort by "Name (A-Z)"
    Then items should be ordered alphabetically by card name

  Scenario: Sort by date added
    When I select sort by "Date Added (Newest)"
    Then items should be ordered by created_at descending

  Scenario: Sort by condition
    When I select sort by "Condition (Best)"
    Then near_mint items appear first, then lightly_played, etc.

  Scenario: Default sort
    Given I have not selected a sort option
    Then items should be sorted by date added (newest first)
```

### AC-3.1.8: Combined Filters

```gherkin
Feature: Combine Multiple Filters

  Scenario: Apply multiple filters
    Given my collection has various cards
    When I filter by set "MH3"
    And I filter by color "Red"
    And I filter by type "Creature"
    Then I should see only red creatures from MH3

  Scenario: Filters use AND logic
    Given I filter by set "MH3" AND color "Blue"
    Then I should see blue cards from MH3
    And I should not see red cards from MH3
    And I should not see blue cards from other sets

  Scenario: Clear all filters
    Given I have multiple filters applied
    When I click "Clear All Filters"
    Then all filters should be reset
    And I should see all items in the collection
```

### AC-3.1.9: URL State Preservation

```gherkin
Feature: Filter State in URL

  Scenario: Filters reflected in URL
    Given I filter by set "MH3" and color "Red"
    Then the URL should include query parameters like "?set=MH3&color=R"

  Scenario: Load filters from URL
    Given I visit "/collections/1/items?set=MH3&color=R"
    Then the set filter should show "MH3" selected
    And the color filter should show "Red" selected
    And the items should be filtered accordingly

  Scenario: Bookmarkable filtered views
    Given I have applied filters
    When I copy the URL and visit it in a new tab
    Then I should see the same filtered view
```

### AC-3.1.10: Empty State

```gherkin
Feature: No Results State

  Scenario: No items match filters
    Given I apply filters that match no items
    Then I should see a message "No items match your filters"
    And I should see a "Clear Filters" button

  Scenario: Helpful empty state
    Given no items match my filters
    Then I should see which filters are applied
    And I should be able to modify individual filters
```

### AC-3.1.11: Filter Counts

```gherkin
Feature: Filter Result Counts

  Scenario: Show filtered count
    Given my collection has 100 items
    When I filter to show 25 items
    Then I should see "25 items" (not "100 items")

  Scenario: Show total in context
    Given I have filtered to 25 of 100 items
    Then I should see "25 of 100 items" or similar indicator
```

---

## Technical Implementation

### Routes

No new routes required. Filtering uses query parameters on the existing index action:

```
GET /collections/:collection_id/items?set=MH3&color=R&type=Creature&condition=near_mint&finish=foil&sort=name_asc
```

### Controller Enhancement

```ruby
# app/controllers/items_controller.rb
class ItemsController < ApplicationController
  def index
    @filters = ItemFilters.new(filter_params)
    items = @collection.items.includes(:storage_unit)

    # Apply filters
    items = @filters.apply(items, card_data: -> { load_cards_for_items(items) })

    # Apply sorting
    items = apply_sort(items)

    @pagy, @items = pagy(items)
    @cards = load_cards_for_items(@items)

    # For filter dropdowns - sets/colors in this collection
    @available_sets = available_sets_for_collection
    @applied_filters = @filters.to_h
  end

  private

  def filter_params
    params.permit(:set, :color, :type, :condition, :finish, :sort)
  end

  def apply_sort(items)
    case params[:sort]
    when "name_asc"
      # Requires join with card data - handled specially
      items.order(created_at: :desc) # fallback, actual sort in memory
    when "name_desc"
      items.order(created_at: :desc)
    when "date_asc"
      items.order(created_at: :asc)
    when "date_desc", nil
      items.order(created_at: :desc)
    when "condition_asc"
      items.order(condition: :asc)
    when "condition_desc"
      items.order(condition: :desc)
    else
      items.order(created_at: :desc)
    end
  end

  def available_sets_for_collection
    # Get unique set codes from items in this collection
    card_uuids = @collection.items.pluck(:card_uuid)
    MTGJSON::Card.where(uuid: card_uuids)
                 .distinct
                 .pluck(:setCode)
                 .compact
                 .sort
  end
end
```

### Filter Service Object

```ruby
# app/services/item_filters.rb
class ItemFilters
  COLORS = %w[W U B R G].freeze
  TYPES = %w[Creature Instant Sorcery Artifact Enchantment Planeswalker Land].freeze
  FOIL_FINISHES = %w[traditional_foil etched glossy textured surge_foil].freeze

  attr_reader :set, :color, :type, :condition, :finish

  def initialize(params)
    @set = params[:set].presence
    @color = params[:color].presence
    @type = params[:type].presence
    @condition = params[:condition].presence
    @finish = params[:finish].presence
  end

  def apply(items, card_data:)
    return items if empty?

    # Load card data for filtering
    cards = card_data.call

    # Filter by item attributes (can be done in SQL)
    items = items.where(condition: condition) if condition.present?
    items = apply_finish_filter(items) if finish.present?

    # Filter by card attributes (requires card lookup)
    if set.present? || color.present? || type.present?
      matching_uuids = filter_card_uuids(cards)
      items = items.where(card_uuid: matching_uuids)
    end

    items
  end

  def empty?
    [set, color, type, condition, finish].all?(&:blank?)
  end

  def to_h
    {
      set: set,
      color: color,
      type: type,
      condition: condition,
      finish: finish
    }.compact
  end

  def active_count
    to_h.size
  end

  private

  def apply_finish_filter(items)
    case finish
    when "foil"
      items.where(finish: FOIL_FINISHES)
    when "nonfoil"
      items.where(finish: "nonfoil")
    else
      items.where(finish: finish)
    end
  end

  def filter_card_uuids(cards)
    cards.values.select do |card|
      matches_set?(card) && matches_color?(card) && matches_type?(card)
    end.map(&:uuid)
  end

  def matches_set?(card)
    return true if set.blank?
    card.setCode == set
  end

  def matches_color?(card)
    return true if color.blank?

    card_colors = parse_colors(card.colors)

    case color
    when "C"
      card_colors.empty?
    when "M"
      card_colors.size > 1
    else
      card_colors.include?(color)
    end
  end

  def matches_type?(card)
    return true if type.blank?
    card.type&.include?(type)
  end

  def parse_colors(colors_string)
    return [] if colors_string.blank?
    # MTGJSON stores colors as JSON array string like '["R","G"]'
    JSON.parse(colors_string) rescue []
  end
end
```

### Stimulus Controller

```javascript
// app/javascript/controllers/item_filters_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "panel", "count", "activeFilters"]
  static values = {
    expanded: { type: Boolean, default: false }
  }

  connect() {
    this.updateActiveFiltersDisplay()
  }

  toggle() {
    this.expandedValue = !this.expandedValue
    this.panelTarget.classList.toggle("hidden", !this.expandedValue)
  }

  filter(event) {
    // Auto-submit on change
    this.formTarget.requestSubmit()
  }

  clearAll(event) {
    event.preventDefault()

    // Clear all select elements
    this.formTarget.querySelectorAll("select").forEach(select => {
      select.value = ""
    })

    this.formTarget.requestSubmit()
  }

  updateActiveFiltersDisplay() {
    if (!this.hasActiveFiltersTarget) return

    const activeCount = this.formTarget.querySelectorAll("select").length
    // Count non-empty selects
    let active = 0
    this.formTarget.querySelectorAll("select").forEach(select => {
      if (select.value) active++
    })

    if (active > 0) {
      this.activeFiltersTarget.textContent = `(${active})`
      this.activeFiltersTarget.classList.remove("hidden")
    } else {
      this.activeFiltersTarget.classList.add("hidden")
    }
  }
}
```

### Views

```erb
<%# app/views/items/_filters.html.erb %>
<div class="mb-6" data-controller="item-filters">
  <!-- Mobile toggle -->
  <button type="button"
          class="sm:hidden flex items-center gap-2 text-gray-700 font-medium mb-4"
          data-action="item-filters#toggle">
    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"/>
    </svg>
    Filters
    <span class="hidden text-indigo-600" data-item-filters-target="activeFilters"></span>
  </button>

  <!-- Filter panel -->
  <div class="hidden sm:block bg-white rounded-lg border border-gray-200 p-4"
       data-item-filters-target="panel">
    <%= form_with url: collection_items_path(@collection), method: :get, local: true,
        data: { item_filters_target: "form", turbo_frame: "items_list" },
        class: "space-y-4" do |f| %>

      <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
        <!-- Set Filter -->
        <div>
          <%= f.label :set, "Set", class: "block text-sm font-medium text-gray-700 mb-1" %>
          <%= f.select :set,
              options_for_select([["All Sets", ""]] + @available_sets.map { |s| [s, s] }, params[:set]),
              {},
              class: "block w-full rounded-md border-gray-300 text-sm",
              data: { action: "change->item-filters#filter" } %>
        </div>

        <!-- Color Filter -->
        <div>
          <%= f.label :color, "Color", class: "block text-sm font-medium text-gray-700 mb-1" %>
          <%= f.select :color,
              options_for_select([
                ["All Colors", ""],
                ["White", "W"],
                ["Blue", "U"],
                ["Black", "B"],
                ["Red", "R"],
                ["Green", "G"],
                ["Colorless", "C"],
                ["Multicolor", "M"]
              ], params[:color]),
              {},
              class: "block w-full rounded-md border-gray-300 text-sm",
              data: { action: "change->item-filters#filter" } %>
        </div>

        <!-- Type Filter -->
        <div>
          <%= f.label :type, "Type", class: "block text-sm font-medium text-gray-700 mb-1" %>
          <%= f.select :type,
              options_for_select([
                ["All Types", ""],
                ["Creature", "Creature"],
                ["Instant", "Instant"],
                ["Sorcery", "Sorcery"],
                ["Artifact", "Artifact"],
                ["Enchantment", "Enchantment"],
                ["Planeswalker", "Planeswalker"],
                ["Land", "Land"]
              ], params[:type]),
              {},
              class: "block w-full rounded-md border-gray-300 text-sm",
              data: { action: "change->item-filters#filter" } %>
        </div>

        <!-- Condition Filter -->
        <div>
          <%= f.label :condition, "Condition", class: "block text-sm font-medium text-gray-700 mb-1" %>
          <%= f.select :condition,
              options_for_select([["All Conditions", ""]] + condition_filter_options, params[:condition]),
              {},
              class: "block w-full rounded-md border-gray-300 text-sm",
              data: { action: "change->item-filters#filter" } %>
        </div>

        <!-- Finish Filter -->
        <div>
          <%= f.label :finish, "Finish", class: "block text-sm font-medium text-gray-700 mb-1" %>
          <%= f.select :finish,
              options_for_select([
                ["All Finishes", ""],
                ["Non-foil", "nonfoil"],
                ["Any Foil", "foil"],
                ["Traditional Foil", "traditional_foil"],
                ["Etched", "etched"]
              ], params[:finish]),
              {},
              class: "block w-full rounded-md border-gray-300 text-sm",
              data: { action: "change->item-filters#filter" } %>
        </div>

        <!-- Sort -->
        <div>
          <%= f.label :sort, "Sort", class: "block text-sm font-medium text-gray-700 mb-1" %>
          <%= f.select :sort,
              options_for_select([
                ["Newest First", "date_desc"],
                ["Oldest First", "date_asc"],
                ["Name (A-Z)", "name_asc"],
                ["Name (Z-A)", "name_desc"],
                ["Condition (Best)", "condition_asc"],
                ["Condition (Worst)", "condition_desc"]
              ], params[:sort] || "date_desc"),
              {},
              class: "block w-full rounded-md border-gray-300 text-sm",
              data: { action: "change->item-filters#filter" } %>
        </div>
      </div>

      <% if @applied_filters.any? %>
        <div class="flex items-center justify-between pt-2 border-t border-gray-100">
          <span class="text-sm text-gray-600">
            <%= pluralize(@pagy.count, "item") %> found
          </span>
          <%= link_to "Clear All",
              collection_items_path(@collection),
              class: "text-sm text-indigo-600 hover:text-indigo-800",
              data: { turbo_frame: "items_list" } %>
        </div>
      <% end %>
    <% end %>
  </div>
</div>
```

### Helper Methods

```ruby
# app/helpers/items_helper.rb (additions)
module ItemsHelper
  def condition_filter_options
    Item.conditions.keys.map do |c|
      [condition_display_name(c), c]
    end
  end

  def color_symbol(color_code)
    {
      "W" => "White",
      "U" => "Blue",
      "B" => "Black",
      "R" => "Red",
      "G" => "Green",
      "C" => "Colorless",
      "M" => "Multicolor"
    }[color_code] || color_code
  end
end
```

---

## Database Changes

**None required.** Filtering uses existing columns and indexes.

### Recommended Index (Optional Performance Enhancement)

```ruby
# If filtering by condition becomes slow with large collections
add_index :items, [:collection_id, :condition]
add_index :items, [:collection_id, :finish]
```

---

## Test Requirements

### Service Object Specs

```ruby
# spec/services/item_filters_spec.rb
require "rails_helper"

RSpec.describe ItemFilters do
  let(:collection) { create(:collection) }
  let(:card_red) { MTGJSON::Card.find_by("colors LIKE ?", "%R%") }
  let(:card_blue) { MTGJSON::Card.find_by("colors LIKE ?", "%U%") }
  let(:card_creature) { MTGJSON::Card.find_by("type LIKE ?", "%Creature%") }

  describe "#empty?" do
    it "returns true with no filters" do
      filters = ItemFilters.new({})
      expect(filters.empty?).to be true
    end

    it "returns false with any filter" do
      filters = ItemFilters.new(set: "MH3")
      expect(filters.empty?).to be false
    end
  end

  describe "#apply" do
    context "condition filter" do
      let!(:nm_item) { create(:item, collection: collection, condition: :near_mint) }
      let!(:lp_item) { create(:item, collection: collection, condition: :lightly_played) }

      it "filters by condition" do
        filters = ItemFilters.new(condition: "near_mint")
        result = filters.apply(collection.items, card_data: -> { {} })

        expect(result).to include(nm_item)
        expect(result).not_to include(lp_item)
      end
    end

    context "finish filter" do
      let!(:nonfoil_item) { create(:item, collection: collection, finish: :nonfoil) }
      let!(:foil_item) { create(:item, collection: collection, finish: :traditional_foil) }
      let!(:etched_item) { create(:item, collection: collection, finish: :etched) }

      it "filters by nonfoil" do
        filters = ItemFilters.new(finish: "nonfoil")
        result = filters.apply(collection.items, card_data: -> { {} })

        expect(result).to include(nonfoil_item)
        expect(result).not_to include(foil_item)
      end

      it "filters by any foil" do
        filters = ItemFilters.new(finish: "foil")
        result = filters.apply(collection.items, card_data: -> { {} })

        expect(result).to include(foil_item)
        expect(result).to include(etched_item)
        expect(result).not_to include(nonfoil_item)
      end
    end

    context "combined filters" do
      it "applies multiple filters with AND logic" do
        nm_foil = create(:item, collection: collection, condition: :near_mint, finish: :traditional_foil)
        nm_nonfoil = create(:item, collection: collection, condition: :near_mint, finish: :nonfoil)
        lp_foil = create(:item, collection: collection, condition: :lightly_played, finish: :traditional_foil)

        filters = ItemFilters.new(condition: "near_mint", finish: "foil")
        result = filters.apply(collection.items, card_data: -> { {} })

        expect(result).to include(nm_foil)
        expect(result).not_to include(nm_nonfoil)
        expect(result).not_to include(lp_foil)
      end
    end
  end

  describe "#to_h" do
    it "returns only non-blank filters" do
      filters = ItemFilters.new(set: "MH3", color: "", condition: "near_mint")
      expect(filters.to_h).to eq({ set: "MH3", condition: "near_mint" })
    end
  end

  describe "#active_count" do
    it "returns count of active filters" do
      filters = ItemFilters.new(set: "MH3", condition: "near_mint")
      expect(filters.active_count).to eq(2)
    end
  end
end
```

### Request Specs

```ruby
# spec/requests/items_filtering_spec.rb
require "rails_helper"

RSpec.describe "Items Filtering", type: :request do
  let(:collection) { create(:collection) }
  let(:card) { MTGJSON::Card.first }

  describe "GET /collections/:id/items with filters" do
    before do
      create(:item, collection: collection, card_uuid: card.uuid, condition: :near_mint, finish: :nonfoil)
      create(:item, collection: collection, card_uuid: card.uuid, condition: :lightly_played, finish: :traditional_foil)
    end

    context "filtering by condition" do
      it "returns only matching items" do
        get collection_items_path(collection), params: { condition: "near_mint" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("1 item")
      end
    end

    context "filtering by finish" do
      it "returns foil items" do
        get collection_items_path(collection), params: { finish: "foil" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Traditional")
      end
    end

    context "sorting" do
      it "sorts by condition" do
        get collection_items_path(collection), params: { sort: "condition_asc" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "combined filters" do
      it "applies all filters" do
        get collection_items_path(collection), params: {
          condition: "near_mint",
          finish: "nonfoil"
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("1 item")
      end
    end

    context "no matching items" do
      it "shows empty state message" do
        get collection_items_path(collection), params: { condition: "damaged" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No items match")
      end
    end
  end
end
```

### System Specs

```ruby
# spec/system/item_filtering_spec.rb
require "rails_helper"

RSpec.describe "Item Filtering", type: :system do
  before do
    driven_by(:selenium_headless)
  end

  let(:collection) { create(:collection, name: "Test Collection") }
  let(:card) { MTGJSON::Card.first }

  describe "filter controls" do
    before do
      create(:item, collection: collection, card_uuid: card.uuid)
      visit collection_items_path(collection)
    end

    it "displays filter dropdowns" do
      expect(page).to have_select("set")
      expect(page).to have_select("color")
      expect(page).to have_select("type")
      expect(page).to have_select("condition")
      expect(page).to have_select("finish")
      expect(page).to have_select("sort")
    end
  end

  describe "filtering by condition" do
    let!(:nm_item) { create(:item, collection: collection, card_uuid: card.uuid, condition: :near_mint) }
    let!(:lp_item) { create(:item, collection: collection, card_uuid: card.uuid, condition: :lightly_played) }

    before { visit collection_items_path(collection) }

    it "filters to show only near mint items" do
      expect(page).to have_content("2 items")

      select "Near mint (NM)", from: "condition"

      expect(page).to have_content("1 item")
    end
  end

  describe "filtering by finish" do
    let!(:nonfoil_item) { create(:item, collection: collection, card_uuid: card.uuid, finish: :nonfoil) }
    let!(:foil_item) { create(:item, collection: collection, card_uuid: card.uuid, finish: :traditional_foil) }

    before { visit collection_items_path(collection) }

    it "filters to show only foil items" do
      select "Any Foil", from: "finish"

      expect(page).to have_content("1 item")
      expect(page).to have_content("Traditional")
    end
  end

  describe "clearing filters" do
    let!(:item) { create(:item, collection: collection, card_uuid: card.uuid, condition: :near_mint) }

    before { visit collection_items_path(collection) }

    it "clears all filters" do
      select "Near mint (NM)", from: "condition"
      expect(page).to have_content("1 item")

      click_link "Clear All"

      expect(page).to have_select("condition", selected: "All Conditions")
    end
  end

  describe "URL state" do
    let!(:item) { create(:item, collection: collection, card_uuid: card.uuid, condition: :near_mint) }

    it "preserves filters in URL" do
      visit collection_items_path(collection, condition: "near_mint", finish: "nonfoil")

      expect(page).to have_select("condition", selected: "Near mint (NM)")
      expect(page).to have_select("finish", selected: "Non-foil")
    end
  end

  describe "empty state" do
    let!(:item) { create(:item, collection: collection, card_uuid: card.uuid, condition: :near_mint) }

    before { visit collection_items_path(collection) }

    it "shows message when no items match" do
      select "Damaged", from: "condition"

      expect(page).to have_content("No items match")
      expect(page).to have_link("Clear")
    end
  end
end
```

### Helper Specs

```ruby
# spec/helpers/items_helper_spec.rb (additions)
RSpec.describe ItemsHelper, type: :helper do
  describe "#condition_filter_options" do
    it "returns all conditions for filtering" do
      options = helper.condition_filter_options
      expect(options.map(&:last)).to include("near_mint", "lightly_played")
    end
  end

  describe "#color_symbol" do
    it "returns color name for code" do
      expect(helper.color_symbol("R")).to eq("Red")
      expect(helper.color_symbol("U")).to eq("Blue")
    end
  end
end
```

---

## UI/UX Specifications

### Filter Bar Layout (Desktop)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Set        Color      Type       Condition   Finish      Sort              │
│ [All Sets▼] [All▼]    [All▼]     [All▼]      [All▼]      [Newest First▼]   │
├─────────────────────────────────────────────────────────────────────────────┤
│ 25 of 100 items found                                    [Clear All]        │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Filter Bar Layout (Mobile)

```
┌─────────────────────────────────┐
│ [🔍] Filters (2)                │
├─────────────────────────────────┤
│ (Filter panel hidden by default)│
│ Tap to expand                   │
└─────────────────────────────────┘

Expanded:
┌─────────────────────────────────┐
│ [🔍] Filters (2)            [✕] │
├─────────────────────────────────┤
│ Set          [All Sets      ▼]  │
│ Color        [Red           ▼]  │
│ Type         [Creature      ▼]  │
│ Condition    [All           ▼]  │
│ Finish       [All           ▼]  │
│ Sort         [Newest First  ▼]  │
├─────────────────────────────────┤
│ 25 items      [Clear All]       │
└─────────────────────────────────┘
```

### Empty State

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                          No items match your filters                        │
│                                                                             │
│                    Filters: Set: MH3 · Color: Red · Type: Land             │
│                                                                             │
│                              [Clear Filters]                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Dependencies

- **Phase 2.2**: Item List View (existing items index)
- **Pagy**: Pagination gem (already in use)
- **Stimulus**: For interactive filter updates
- **Turbo Frames**: For partial page updates (optional enhancement)

---

## Definition of Done

- [ ] Filter controls visible on items index page
- [ ] Set filter dropdown populated with sets in collection
- [ ] Color filter with W/U/B/R/G/Colorless/Multicolor options
- [ ] Type filter with major card types
- [ ] Condition filter using Item enum values
- [ ] Finish filter with non-foil and foil options
- [ ] Sort dropdown with name, date, condition options
- [ ] Filters apply with AND logic
- [ ] Filter state preserved in URL query parameters
- [ ] Bookmarkable filtered URLs work correctly
- [ ] Empty state shown when no items match
- [ ] "Clear All" resets all filters
- [ ] Item count updates to show filtered count
- [ ] Mobile-responsive filter panel
- [ ] Stimulus controller for filter interactions
- [ ] ItemFilters service object with full test coverage
- [ ] Request specs for all filter combinations
- [ ] System specs for user filter workflows
- [ ] `bin/ci` passes

---

## Future Enhancements (Not in MVP)

- Filter by rarity
- Filter by mana value/CMC
- Filter by storage unit
- Filter by signed/altered/misprint
- Save filter presets
- Quick filter chips for common filters
- Card name text search within collection
- Advanced search syntax
- Filter by price range (Phase 4)
