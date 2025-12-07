# Phase 3.2: Storage Unit Contents

## Feature Overview

Enable users to view items organized by storage location, providing a physical-location-centric view of their collection. This feature bridges the gap between digital inventory and physical organization by answering "What's in this box/binder/deck?"

**Priority**: High (essential for physical organization)
**Dependencies**: Phase 2.2 (Item List), existing Storage Unit CRUD
**Estimated Complexity**: Medium

---

## User Stories

### US-3.2.1: View Items in Storage Unit
**As a** collector
**I want to** see all items stored in a specific storage unit
**So that** I know what's physically in that container

### US-3.2.2: View Items in Nested Storage
**As a** collector
**I want to** see items in a storage unit and all its nested units
**So that** I can see everything in a box including its deck boxes

### US-3.2.3: Navigate Storage Hierarchy
**As a** collector
**I want to** navigate between parent and child storage units
**So that** I can drill down or up in my storage organization

### US-3.2.4: See Item Counts per Storage Unit
**As a** collector
**I want to** see how many items are in each storage unit
**So that** I can understand capacity and distribution

### US-3.2.5: View Loose Items
**As a** collector
**I want to** see items not in any storage unit
**So that** I can find cards that need to be organized

### US-3.2.6: Quick Actions from Storage View
**As a** collector
**I want to** move items directly from the storage view
**So that** I can reorganize without navigating away

---

## Acceptance Criteria

### AC-3.2.1: Storage Unit Show Page with Items

```gherkin
Feature: View Storage Unit Contents

  Scenario: Storage unit page shows items
    Given I have a storage unit "Box A" with 10 items
    When I view the storage unit "Box A"
    Then I should see a list of all 10 items
    And each item should show the card name and condition

  Scenario: Storage unit page shows item count
    Given I have a storage unit "Box A" with 10 items
    When I view the storage unit details
    Then I should see "10 items" in the storage unit info

  Scenario: Empty storage unit
    Given I have a storage unit "Empty Box" with no items
    When I view "Empty Box"
    Then I should see "No items in this storage unit"
    And I should see a link to add cards
```

### AC-3.2.2: Nested Storage View

```gherkin
Feature: View Nested Storage Contents

  Scenario: See items in nested units
    Given "Big Box" contains "Deck Box 1" which contains 5 items
    And "Big Box" directly contains 3 items
    When I view "Big Box"
    Then I should see the 3 direct items
    And I should see "Deck Box 1" as a nested unit
    And I should see "Deck Box 1" contains 5 items

  Scenario: Option to include nested items
    Given "Big Box" contains nested units with items
    When I view "Big Box"
    Then I should see a toggle "Include nested items"
    When I enable "Include nested items"
    Then I should see all items from Big Box and its children

  Scenario: Nested unit navigation
    Given "Big Box" contains "Deck Box 1"
    When I view "Big Box"
    And I click on "Deck Box 1"
    Then I should see the contents of "Deck Box 1"
    And I should see a breadcrumb back to "Big Box"
```

### AC-3.2.3: Storage Navigation

```gherkin
Feature: Storage Navigation

  Scenario: Breadcrumb navigation
    Given "Box A" contains "Deck Box 1" contains "Deck"
    When I view "Deck"
    Then I should see breadcrumbs: Collection > Box A > Deck Box 1 > Deck

  Scenario: Navigate to parent
    Given I am viewing "Deck Box 1" inside "Box A"
    When I click the parent link "Box A"
    Then I should see the contents of "Box A"

  Scenario: Quick jump to collection
    Given I am viewing a deeply nested storage unit
    When I click the collection name in breadcrumbs
    Then I should go to the collection's item list
```

### AC-3.2.4: Item Counts on Storage Units

```gherkin
Feature: Item Counts

  Scenario: Direct item count
    Given "Box A" directly contains 10 items
    And "Box A" has no nested storage units
    When I view the storage units list
    Then "Box A" should show "10 items"

  Scenario: Nested item count
    Given "Box A" directly contains 5 items
    And "Box A" contains "Deck Box" with 3 items
    When I view the storage units list
    Then "Box A" should show "5 items (8 total)"
    Or "Box A" should show "5 items + 3 nested"

  Scenario: Count updates after item move
    Given "Box A" has 10 items
    When I move an item from "Box A" to "Box B"
    And I view the storage units list
    Then "Box A" should show "9 items"
    And "Box B" should show the updated count
```

### AC-3.2.5: Loose Items View

```gherkin
Feature: Loose Items

  Scenario: View loose items
    Given my collection has 5 items without storage units
    When I click "Loose Items" or "Unsorted Items"
    Then I should see all 5 items without storage units

  Scenario: Loose items count in collection
    Given my collection has 10 items in storage
    And 5 items without storage units
    When I view the collection
    Then I should see "5 loose items" or similar indicator

  Scenario: Move loose item to storage
    Given I am viewing loose items
    When I click "Move" on an item
    Then I should be able to assign it to a storage unit
```

### AC-3.2.6: Quick Actions

```gherkin
Feature: Quick Actions from Storage View

  Scenario: Move item from storage view
    Given I am viewing "Box A" contents
    When I click the move icon on an item
    Then I should see the move dialog
    And I should be able to move it to another storage unit

  Scenario: View item details
    Given I am viewing "Box A" contents
    When I click on an item card
    Then I should go to the item detail page
    And I should see a link back to "Box A"

  Scenario: Bulk select items (stretch goal)
    Given I am viewing "Box A" contents
    When I enable selection mode
    And I select multiple items
    Then I should be able to move them all at once
```

---

## Technical Implementation

### Routes

```ruby
# config/routes.rb
resources :collections do
  resources :storage_units, shallow: true do
    member do
      get :items  # GET /storage_units/:id/items - show items in unit
    end
  end

  # Special route for loose items
  get "items/loose", to: "items#loose", as: :loose_items
end
```

### Controller

```ruby
# app/controllers/storage_units_controller.rb
class StorageUnitsController < ApplicationController
  def show
    @storage_unit = StorageUnit.find(params[:id])
    @collection = @storage_unit.collection

    # Direct items in this storage unit
    @direct_items = @storage_unit.items.includes(:collection)
    @cards = load_cards_for_items(@direct_items)

    # Nested storage units with their item counts
    @nested_units = @storage_unit.children.includes(:items)

    # Calculate counts
    @direct_count = @direct_items.count
    @nested_count = count_nested_items(@storage_unit)
    @total_count = @direct_count + @nested_count

    # Breadcrumb ancestors
    @ancestors = build_ancestors(@storage_unit)
  end

  def items
    @storage_unit = StorageUnit.find(params[:id])
    @collection = @storage_unit.collection

    items = if params[:include_nested] == "true"
      all_items_in_unit(@storage_unit)
    else
      @storage_unit.items
    end

    @pagy, @items = pagy(items.includes(:storage_unit).order(created_at: :desc))
    @cards = load_cards_for_items(@items)
    @include_nested = params[:include_nested] == "true"
  end

  private

  def count_nested_items(unit)
    count = 0
    unit.children.each do |child|
      count += child.items.count
      count += count_nested_items(child)
    end
    count
  end

  def all_items_in_unit(unit)
    unit_ids = collect_all_child_ids(unit) + [unit.id]
    Item.where(storage_unit_id: unit_ids)
  end

  def collect_all_child_ids(unit)
    ids = []
    unit.children.each do |child|
      ids << child.id
      ids.concat(collect_all_child_ids(child))
    end
    ids
  end

  def build_ancestors(unit)
    ancestors = []
    current = unit.parent
    while current
      ancestors.unshift(current)
      current = current.parent
    end
    ancestors
  end

  def load_cards_for_items(items)
    uuids = items.map(&:card_uuid).uniq
    MTGJSON::Card.includes(:set, :identifiers)
                 .where(uuid: uuids)
                 .index_by(&:uuid)
  end
end
```

```ruby
# app/controllers/items_controller.rb (addition)
class ItemsController < ApplicationController
  def loose
    @collection = Collection.find(params[:collection_id])
    items = @collection.items.where(storage_unit_id: nil)

    @pagy, @items = pagy(items.order(created_at: :desc))
    @cards = load_cards_for_items(@items)
  end
end
```

### Model Enhancement

```ruby
# app/models/storage_unit.rb (additions)
class StorageUnit < ApplicationRecord
  # Existing associations...

  # Count items including nested units
  def total_items_count
    items.count + children.sum(&:total_items_count)
  end

  # Get all items including nested
  def all_items
    item_ids = collect_all_item_ids
    Item.where(id: item_ids)
  end

  private

  def collect_all_item_ids
    ids = items.pluck(:id)
    children.each do |child|
      ids.concat(child.collect_all_item_ids)
    end
    ids
  end
end
```

```ruby
# app/models/collection.rb (additions)
class Collection < ApplicationRecord
  # Existing associations...

  def loose_items
    items.where(storage_unit_id: nil)
  end

  def loose_items_count
    loose_items.count
  end
end
```

### Views

```erb
<%# app/views/storage_units/show.html.erb %>
<% content_for :title, @storage_unit.name %>

<article class="w-full">
  <!-- Breadcrumb Navigation -->
  <nav class="mb-6" aria-label="Breadcrumb">
    <ol class="flex items-center gap-2 text-sm text-gray-500">
      <li>
        <%= link_to @collection.name, @collection, class: "hover:text-gray-700" %>
      </li>
      <% @ancestors.each do |ancestor| %>
        <li class="flex items-center gap-2">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
          </svg>
          <%= link_to ancestor.name, ancestor, class: "hover:text-gray-700" %>
        </li>
      <% end %>
      <li class="flex items-center gap-2">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
        <span class="font-medium text-gray-900"><%= @storage_unit.name %></span>
      </li>
    </ol>
  </nav>

  <!-- Storage Unit Header -->
  <header class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-8">
    <div>
      <div class="flex items-center gap-3 mb-2">
        <%= render "storage_units/type_badge", storage_unit: @storage_unit %>
        <h1 class="text-3xl font-bold text-gray-900"><%= @storage_unit.name %></h1>
      </div>

      <% if @storage_unit.description.present? %>
        <p class="text-gray-600 mb-2"><%= @storage_unit.description %></p>
      <% end %>

      <% if @storage_unit.location.present? %>
        <p class="text-sm text-gray-500">
          <span class="inline-flex items-center gap-1">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
            </svg>
            <%= @storage_unit.location %>
          </span>
        </p>
      <% end %>

      <div class="mt-3 flex items-center gap-4 text-sm">
        <span class="text-gray-600">
          <strong><%= @direct_count %></strong> items directly stored
        </span>
        <% if @nested_count > 0 %>
          <span class="text-gray-600">
            <strong><%= @total_count %></strong> items total (including nested)
          </span>
        <% end %>
      </div>
    </div>

    <div class="flex items-center gap-2">
      <%= link_to edit_storage_unit_path(@storage_unit),
          class: "inline-flex items-center gap-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors" do %>
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
        </svg>
        Edit
      <% end %>
    </div>
  </header>

  <!-- Nested Storage Units -->
  <% if @nested_units.any? %>
    <section class="mb-8">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">Nested Storage Units</h2>
      <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <% @nested_units.each do |nested| %>
          <%= link_to nested, class: "block p-4 bg-white rounded-lg border border-gray-200 hover:border-indigo-300 hover:shadow-sm transition-all" do %>
            <div class="flex items-center gap-3">
              <%= render "storage_units/type_badge", storage_unit: nested %>
              <div>
                <h3 class="font-medium text-gray-900"><%= nested.name %></h3>
                <p class="text-sm text-gray-500"><%= pluralize(nested.total_items_count, "item") %></p>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </section>
  <% end %>

  <!-- Items in this Storage Unit -->
  <section>
    <div class="flex items-center justify-between mb-4">
      <h2 class="text-lg font-semibold text-gray-900">Items in <%= @storage_unit.name %></h2>
      <% if @nested_units.any? %>
        <%= link_to items_storage_unit_path(@storage_unit, include_nested: true),
            class: "text-sm text-indigo-600 hover:text-indigo-800" do %>
          View all <%= @total_count %> items including nested
        <% end %>
      <% end %>
    </div>

    <% if @direct_items.any? %>
      <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        <% @direct_items.each do |item| %>
          <%= render "items/item_card", item: item, card: @cards[item.card_uuid] %>
        <% end %>
      </div>
    <% else %>
      <div class="text-center py-12 bg-gray-50 rounded-lg">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"/>
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900">No items directly in this unit</h3>
        <p class="mt-1 text-sm text-gray-500">
          <% if @nested_count > 0 %>
            There are <%= @nested_count %> items in nested storage units.
          <% else %>
            Add cards from the card browser to this storage unit.
          <% end %>
        </p>
        <div class="mt-4">
          <%= link_to cards_path, class: "inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700" do %>
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
            </svg>
            Browse Cards
          <% end %>
        </div>
      </div>
    <% end %>
  </section>
</article>
```

```erb
<%# app/views/storage_units/items.html.erb %>
<% content_for :title, "Items in #{@storage_unit.name}" %>

<article class="w-full">
  <nav class="mb-6">
    <%= link_to @storage_unit, class: "inline-flex items-center gap-1 text-indigo-600 hover:text-indigo-800" do %>
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
      </svg>
      Back to <%= @storage_unit.name %>
    <% end %>
  </nav>

  <header class="mb-8">
    <h1 class="text-3xl font-bold text-gray-900">
      <%= @include_nested ? "All Items" : "Items" %> in <%= @storage_unit.name %>
    </h1>
    <p class="mt-1 text-gray-600">
      <%= pluralize(@pagy.count, "item") %>
      <%= "including nested storage units" if @include_nested %>
    </p>

    <% if @storage_unit.children.any? %>
      <div class="mt-4 flex gap-4">
        <% if @include_nested %>
          <%= link_to "Show direct items only",
              items_storage_unit_path(@storage_unit),
              class: "text-sm text-indigo-600 hover:text-indigo-800" %>
        <% else %>
          <%= link_to "Include nested items",
              items_storage_unit_path(@storage_unit, include_nested: true),
              class: "text-sm text-indigo-600 hover:text-indigo-800" %>
        <% end %>
      </div>
    <% end %>
  </header>

  <% if @items.any? %>
    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      <% @items.each do |item| %>
        <%= render "items/item_card", item: item, card: @cards[item.card_uuid], show_storage: @include_nested %>
      <% end %>
    </div>

    <% if @pagy.last > 1 %>
      <nav class="mt-8 flex justify-center">
        <%== @pagy.series_nav %>
      </nav>
    <% end %>
  <% else %>
    <%= render "items/empty_state", collection: @collection %>
  <% end %>
</article>
```

```erb
<%# app/views/items/loose.html.erb %>
<% content_for :title, "Loose Items - #{@collection.name}" %>

<article class="w-full">
  <nav class="mb-6">
    <%= link_to collection_items_path(@collection), class: "inline-flex items-center gap-1 text-indigo-600 hover:text-indigo-800" do %>
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
      </svg>
      Back to All Items
    <% end %>
  </nav>

  <header class="mb-8">
    <h1 class="text-3xl font-bold text-gray-900">Loose Items</h1>
    <p class="mt-1 text-gray-600">
      <%= pluralize(@pagy.count, "item") %> not assigned to any storage unit
    </p>
  </header>

  <% if @items.any? %>
    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      <% @items.each do |item| %>
        <%= render "items/item_card", item: item, card: @cards[item.card_uuid] %>
      <% end %>
    </div>

    <% if @pagy.last > 1 %>
      <nav class="mt-8 flex justify-center">
        <%== @pagy.series_nav %>
      </nav>
    <% end %>
  <% else %>
    <div class="text-center py-12 bg-gray-50 rounded-lg">
      <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
      </svg>
      <h3 class="mt-2 text-sm font-medium text-gray-900">All items are organized</h3>
      <p class="mt-1 text-sm text-gray-500">
        Every item in this collection has been assigned to a storage unit.
      </p>
    </div>
  <% end %>
</article>
```

---

## Database Changes

**None required.** Uses existing tables and relationships.

---

## Test Requirements

### Model Specs

```ruby
# spec/models/storage_unit_spec.rb (additions)
RSpec.describe StorageUnit, type: :model do
  describe "#total_items_count" do
    let(:collection) { create(:collection) }
    let(:parent) { create(:storage_unit, collection: collection) }
    let(:child) { create(:storage_unit, collection: collection, parent: parent) }

    it "counts direct items" do
      create_list(:item, 3, collection: collection, storage_unit: parent)
      expect(parent.total_items_count).to eq(3)
    end

    it "includes nested items in count" do
      create_list(:item, 2, collection: collection, storage_unit: parent)
      create_list(:item, 3, collection: collection, storage_unit: child)

      expect(parent.total_items_count).to eq(5)
    end

    it "handles deeply nested units" do
      grandchild = create(:storage_unit, collection: collection, parent: child)
      create(:item, collection: collection, storage_unit: grandchild)

      expect(parent.total_items_count).to eq(1)
    end
  end

  describe "#all_items" do
    let(:collection) { create(:collection) }
    let(:parent) { create(:storage_unit, collection: collection) }
    let(:child) { create(:storage_unit, collection: collection, parent: parent) }

    it "returns items from unit and children" do
      item1 = create(:item, collection: collection, storage_unit: parent)
      item2 = create(:item, collection: collection, storage_unit: child)

      expect(parent.all_items).to contain_exactly(item1, item2)
    end
  end
end
```

```ruby
# spec/models/collection_spec.rb (additions)
RSpec.describe Collection, type: :model do
  describe "#loose_items" do
    let(:collection) { create(:collection) }
    let(:storage_unit) { create(:storage_unit, collection: collection) }

    it "returns items without storage unit" do
      loose = create(:item, collection: collection, storage_unit: nil)
      stored = create(:item, collection: collection, storage_unit: storage_unit)

      expect(collection.loose_items).to include(loose)
      expect(collection.loose_items).not_to include(stored)
    end
  end

  describe "#loose_items_count" do
    let(:collection) { create(:collection) }

    it "returns count of unsorted items" do
      create_list(:item, 3, collection: collection, storage_unit: nil)
      expect(collection.loose_items_count).to eq(3)
    end
  end
end
```

### Request Specs

```ruby
# spec/requests/storage_units_spec.rb (additions)
RSpec.describe "Storage Unit Contents", type: :request do
  let(:collection) { create(:collection) }
  let(:storage_unit) { create(:storage_unit, collection: collection, name: "Box A") }
  let(:card) { MTGJSON::Card.first }

  describe "GET /storage_units/:id" do
    context "with items" do
      before do
        create_list(:item, 3, collection: collection, storage_unit: storage_unit, card_uuid: card.uuid)
      end

      it "shows item count" do
        get storage_unit_path(storage_unit)
        expect(response.body).to include("3 items")
      end

      it "displays items" do
        get storage_unit_path(storage_unit)
        expect(response.body).to include(card.name)
      end
    end

    context "with nested units" do
      let(:nested) { create(:storage_unit, collection: collection, parent: storage_unit, name: "Deck Box") }

      before do
        create_list(:item, 2, collection: collection, storage_unit: storage_unit, card_uuid: card.uuid)
        create_list(:item, 3, collection: collection, storage_unit: nested, card_uuid: card.uuid)
      end

      it "shows nested unit" do
        get storage_unit_path(storage_unit)
        expect(response.body).to include("Deck Box")
      end

      it "shows total count" do
        get storage_unit_path(storage_unit)
        expect(response.body).to include("5 items total")
      end
    end

    context "empty storage unit" do
      it "shows empty state" do
        get storage_unit_path(storage_unit)
        expect(response.body).to include("No items")
      end
    end
  end

  describe "GET /storage_units/:id/items" do
    let(:nested) { create(:storage_unit, collection: collection, parent: storage_unit) }

    before do
      create(:item, collection: collection, storage_unit: storage_unit, card_uuid: card.uuid)
      create(:item, collection: collection, storage_unit: nested, card_uuid: card.uuid)
    end

    it "shows only direct items by default" do
      get items_storage_unit_path(storage_unit)
      expect(response.body).to include("1 item")
    end

    it "includes nested items when requested" do
      get items_storage_unit_path(storage_unit, include_nested: true)
      expect(response.body).to include("2 items")
    end
  end
end
```

```ruby
# spec/requests/items_spec.rb (additions)
RSpec.describe "Loose Items", type: :request do
  let(:collection) { create(:collection) }
  let(:storage_unit) { create(:storage_unit, collection: collection) }
  let(:card) { MTGJSON::Card.first }

  describe "GET /collections/:id/items/loose" do
    before do
      create(:item, collection: collection, storage_unit: nil, card_uuid: card.uuid)
      create(:item, collection: collection, storage_unit: storage_unit, card_uuid: card.uuid)
    end

    it "shows only loose items" do
      get loose_items_collection_path(collection)
      expect(response.body).to include("1 item")
    end

    it "does not show stored items" do
      get loose_items_collection_path(collection)
      expect(response.body).not_to include(storage_unit.name)
    end
  end
end
```

### System Specs

```ruby
# spec/system/storage_contents_spec.rb
require "rails_helper"

RSpec.describe "Storage Unit Contents", type: :system do
  before { driven_by(:selenium_headless) }

  let(:collection) { create(:collection, name: "Test Collection") }
  let(:storage_unit) { create(:storage_unit, collection: collection, name: "Box A") }
  let(:card) { MTGJSON::Card.first }

  describe "viewing storage unit with items" do
    before do
      create_list(:item, 3, collection: collection, storage_unit: storage_unit, card_uuid: card.uuid)
    end

    it "displays items in the storage unit" do
      visit storage_unit_path(storage_unit)

      expect(page).to have_content("Box A")
      expect(page).to have_content("3 items")
      expect(page).to have_content(card.name)
    end
  end

  describe "navigating nested storage" do
    let(:nested) { create(:storage_unit, collection: collection, parent: storage_unit, name: "Deck Box") }

    before do
      create(:item, collection: collection, storage_unit: nested, card_uuid: card.uuid)
    end

    it "shows nested units" do
      visit storage_unit_path(storage_unit)
      expect(page).to have_content("Deck Box")
    end

    it "navigates to nested unit" do
      visit storage_unit_path(storage_unit)
      click_link "Deck Box"
      expect(page).to have_current_path(storage_unit_path(nested))
    end

    it "shows breadcrumb navigation" do
      visit storage_unit_path(nested)
      expect(page).to have_link("Box A")
      expect(page).to have_link(collection.name)
    end

    it "navigates back to parent" do
      visit storage_unit_path(nested)
      click_link "Box A"
      expect(page).to have_current_path(storage_unit_path(storage_unit))
    end
  end

  describe "viewing all items including nested" do
    let(:nested) { create(:storage_unit, collection: collection, parent: storage_unit, name: "Deck Box") }

    before do
      create(:item, collection: collection, storage_unit: storage_unit, card_uuid: card.uuid)
      create(:item, collection: collection, storage_unit: nested, card_uuid: card.uuid)
    end

    it "shows option to include nested items" do
      visit storage_unit_path(storage_unit)
      expect(page).to have_link("View all 2 items")
    end

    it "shows all items when nested included" do
      visit items_storage_unit_path(storage_unit, include_nested: true)
      expect(page).to have_content("2 items")
    end
  end

  describe "loose items" do
    before do
      create(:item, collection: collection, storage_unit: nil, card_uuid: card.uuid)
    end

    it "shows loose items count on collection" do
      visit collection_path(collection)
      expect(page).to have_content("1 loose")
    end

    it "displays loose items" do
      visit loose_items_collection_path(collection)
      expect(page).to have_content("Loose Items")
      expect(page).to have_content(card.name)
    end
  end
end
```

---

## UI/UX Specifications

### Storage Unit Show Page

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Test Collection > Box A                                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│ [📦] Box A                                                      [ Edit ]    │
│ Binder for standard cards                                                   │
│ 📍 Shelf 2, left side                                                      │
│                                                                             │
│ 5 items directly stored · 12 items total (including nested)                │
├─────────────────────────────────────────────────────────────────────────────┤
│ Nested Storage Units                                                        │
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐                │
│ │ [🗃️] Deck Box 1  │ │ [🗃️] Deck Box 2  │ │ [📖] Binder     │                │
│ │ 3 items         │ │ 2 items         │ │ 2 items         │                │
│ └─────────────────┘ └─────────────────┘ └─────────────────┘                │
├─────────────────────────────────────────────────────────────────────────────┤
│ Items in Box A                          View all 12 items including nested →│
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                                   │
│ │CARD │ │CARD │ │CARD │ │CARD │ │CARD │                                   │
│ │ 1   │ │ 2   │ │ 3   │ │ 4   │ │ 5   │                                   │
│ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘                                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Loose Items View

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ ← Back to All Items                                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│ Loose Items                                                                 │
│ 8 items not assigned to any storage unit                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐          │
│ │CARD │ │CARD │ │CARD │ │CARD │ │CARD │ │CARD │ │CARD │ │CARD │          │
│ │ 1   │ │ 2   │ │ 3   │ │ 4   │ │ 5   │ │ 6   │ │ 7   │ │ 8   │          │
│ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Dependencies

- **Phase 2.2**: Item List View (item card partial)
- **Existing Storage Unit CRUD**: Storage unit views and controller
- **Pagy**: Pagination for items list

---

## Definition of Done

- [ ] Storage unit show page displays items in that unit
- [ ] Item count shown on storage unit page
- [ ] Nested storage units visible with their item counts
- [ ] Navigation to nested storage units works
- [ ] Breadcrumb navigation shows hierarchy
- [ ] "Include nested items" toggle works
- [ ] Loose items route and view implemented
- [ ] Loose items count shown on collection page
- [ ] Empty states for storage units without items
- [ ] `StorageUnit#total_items_count` method implemented
- [ ] `Collection#loose_items` scope implemented
- [ ] Model specs for item counting methods
- [ ] Request specs for storage contents endpoints
- [ ] System specs for navigation flows
- [ ] `bin/ci` passes

---

## Future Enhancements (Not in MVP)

- Drag and drop items between storage units
- Bulk move items from storage view
- Storage unit capacity tracking
- Visual indicator when storage unit is "full"
- Search within storage unit
- Print storage unit contents
- QR codes for storage unit labels
