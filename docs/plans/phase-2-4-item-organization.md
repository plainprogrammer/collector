# Phase 2.4: Item Organization

## Feature Overview

Enable users to move items between storage units and collections, providing flexible organization of their card collection. This feature allows collectors to reorganize their physical cards and have the digital inventory reflect those changes.

**Priority**: High (important for collection management)
**Dependencies**: Phase 2.1, Phase 2.2, Phase 2.3
**Estimated Complexity**: Medium

---

## User Stories

### US-2.4.1: Move Item to Different Storage Unit
**As a** collector
**I want to** move an item to a different storage unit within the same collection
**So that** I can reorganize my physical cards

### US-2.4.2: Remove Item from Storage Unit
**As a** collector
**I want to** remove an item from its storage unit (make it "loose")
**So that** I can represent cards not in any container

### US-2.4.3: Move Item to Different Collection
**As a** collector
**I want to** move an item to a different collection
**So that** I can reorganize across collections (e.g., main to trade binder)

### US-2.4.4: Confirm Cross-Collection Moves
**As a** collector
**I want to** confirm when moving items between collections
**So that** I don't accidentally move cards

### US-2.4.5: Quick Storage Change
**As a** collector
**I want to** quickly change an item's storage without going through full edit
**So that** I can efficiently reorganize many cards

---

## Acceptance Criteria

### AC-2.4.1: Move Within Same Collection

```gherkin
Feature: Move Item to Storage Unit

  Scenario: Move item to different storage unit
    Given my item is in "Box A"
    And my collection has "Box A" and "Box B"
    When I move the item to "Box B"
    Then the item should be in "Box B"
    And the item should remain in the same collection

  Scenario: Remove item from storage unit
    Given my item is in "Box A"
    When I select "No storage unit (loose)"
    And I save the change
    Then the item should have no storage unit
    And the item should be marked as "loose"

  Scenario: Move loose item to storage unit
    Given my item has no storage unit
    When I select "Box A"
    And I save the change
    Then the item should be in "Box A"
```

### AC-2.4.2: Move Between Collections

```gherkin
Feature: Move Item to Different Collection

  Scenario: Move item to different collection
    Given my item is in collection "Main Collection"
    And I have another collection "Trade Binder"
    When I move the item to "Trade Binder"
    Then the item should be in "Trade Binder"
    And the item should not be in "Main Collection"

  Scenario: Confirmation required for cross-collection move
    Given I am moving an item to a different collection
    When I select the new collection
    Then I should see a confirmation dialog
    And I should be warned about storage unit changes

  Scenario: Storage unit cleared on collection move
    Given my item is in "Box A" in "Main Collection"
    And "Trade Binder" has different storage units
    When I move the item to "Trade Binder"
    Then the item's storage unit should be cleared (loose)
    Or I should be prompted to select a new storage unit

  Scenario: Select new storage unit during move
    Given I am moving an item to "Trade Binder"
    And "Trade Binder" has "Binder Section 1"
    When I select "Trade Binder" as the destination
    Then I should be able to select "Binder Section 1"
    And the item should be placed in "Binder Section 1"
```

### AC-2.4.3: Move Item Interface

```gherkin
Feature: Move Item Interface

  Scenario: Access move from item detail
    Given I am viewing an item detail page
    Then I should see a "Move" button or option

  Scenario: Access move from edit form
    Given I am editing an item
    Then I should be able to change the collection
    And I should see storage units update when collection changes

  Scenario: Move dialog/form
    When I click "Move" on an item
    Then I should see a form with:
      | field           | type     |
      | collection      | dropdown |
      | storage unit    | dropdown |
    And the current values should be pre-selected
```

### AC-2.4.4: Validation and Safety

```gherkin
Feature: Move Validation

  Scenario: Cannot move to same location
    Given my item is in "Box A"
    When I try to move it to "Box A"
    Then I should see "Item is already in this location"
    Or the save button should be disabled

  Scenario: Storage unit must belong to collection
    Given I select collection "Trade Binder"
    When I view the storage unit dropdown
    Then I should only see storage units from "Trade Binder"
    And I should not see storage units from other collections
```

### AC-2.4.5: Bulk Move (Stretch Goal)

```gherkin
Feature: Bulk Move Items

  Scenario: Select multiple items
    Given I am on the collection items list
    Then I should see checkboxes to select items
    When I check multiple items
    Then I should see a "Move Selected" button

  Scenario: Move multiple items at once
    Given I have selected 5 items
    When I click "Move Selected"
    And I select a destination storage unit
    Then all 5 items should be moved
    And I should see "5 items moved to Box B"

  Note: Bulk operations are a stretch goal for MVP.
  The UI should not preclude this feature, but full
  implementation is deferred.
```

---

## Technical Implementation

### Routes

The move functionality can be implemented using the existing `update` action, or as a dedicated action:

```ruby
# config/routes.rb
# Items are nested under collections with shallow routing
resources :collections do
  resources :items, shallow: true do
    member do
      get :move       # Show move form
      patch :relocate # Process move
    end
  end
  resources :storage_units, shallow: true
end
```

Alternative: Use the existing edit/update flow with enhanced UI.

### Controller

```ruby
# app/controllers/items_controller.rb (additions)
class ItemsController < ApplicationController
  # Option 1: Dedicated move action
  def move
    @item = Item.find(params[:id])
    @collections = Collection.order(:name)
    @current_storage_units = @item.collection.storage_units.order(:name)
  end

  def relocate
    @item = Item.find(params[:id])
    old_collection = @item.collection

    # If collection changed, handle storage unit
    if params[:item][:collection_id].to_i != @item.collection_id
      # Clear storage unit if moving to different collection
      # unless a new one is specified
      params[:item][:storage_unit_id] = nil if params[:item][:storage_unit_id].blank?
    end

    if @item.update(relocate_params)
      flash[:notice] = build_move_message(old_collection, @item)
      redirect_to @item
    else
      @collections = Collection.order(:name)
      render :move, status: :unprocessable_entity
    end
  end

  private

  def relocate_params
    params.require(:item).permit(:collection_id, :storage_unit_id)
  end

  def build_move_message(old_collection, item)
    if old_collection.id != item.collection_id
      "Item moved to #{item.collection.name}"
    elsif item.storage_unit
      "Item moved to #{item.storage_unit.name}"
    else
      "Item moved to loose storage"
    end
  end
end
```

### Storage Units JSON Endpoint

For dynamic storage unit loading when collection changes:

```ruby
# app/controllers/storage_units_controller.rb (addition)
class StorageUnitsController < ApplicationController
  def index
    @collection = Collection.find(params[:collection_id])
    @storage_units = @collection.storage_units.order(:name)

    respond_to do |format|
      format.html
      format.json { render json: @storage_units.select(:id, :name, :storage_unit_type) }
    end
  end
end
```

### Stimulus Controller for Dynamic Updates

```javascript
// app/javascript/controllers/item_move_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["collection", "storageUnit", "warning"]
  static values = {
    originalCollection: Number,
    storageUnitsUrl: String
  }

  connect() {
    this.originalCollectionValue = parseInt(this.collectionTarget.value)
  }

  collectionChanged() {
    const newCollectionId = this.collectionTarget.value
    const isMovingCollections = parseInt(newCollectionId) !== this.originalCollectionValue

    // Show/hide warning about storage unit being cleared
    if (this.hasWarningTarget) {
      this.warningTarget.classList.toggle("hidden", !isMovingCollections)
    }

    // Load storage units for new collection
    this.loadStorageUnits(newCollectionId)
  }

  async loadStorageUnits(collectionId) {
    if (!collectionId) {
      this.storageUnitTarget.innerHTML = '<option value="">No storage unit (loose)</option>'
      return
    }

    try {
      const response = await fetch(`/collections/${collectionId}/storage_units.json`)
      const units = await response.json()

      let options = '<option value="">No storage unit (loose)</option>'
      units.forEach(unit => {
        options += `<option value="${unit.id}">${unit.name}</option>`
      })
      this.storageUnitTarget.innerHTML = options
    } catch (error) {
      console.error("Failed to load storage units:", error)
    }
  }
}
```

### Views

```
app/views/items/
├── move.html.erb           # Move item form (if using dedicated action)
├── _move_form.html.erb     # Move form partial
└── _move_warning.html.erb  # Cross-collection warning
```

### Move Form View

```erb
<%# app/views/items/move.html.erb %>
<% content_for :title, "Move Item" %>

<div class="max-w-lg mx-auto">
  <nav class="mb-6">
    <%= link_to "← Back to Item", @item, class: "text-indigo-600 hover:text-indigo-800" %>
  </nav>

  <h1 class="text-2xl font-bold mb-6">Move Item</h1>

  <div class="bg-white rounded-lg shadow-sm border p-6">
    <!-- Item Preview -->
    <div class="flex gap-4 mb-6 pb-6 border-b">
      <% card = @item.card %>
      <% if card %>
        <%= card_image_tag(card, size: :small, class: "w-16 rounded") %>
      <% end %>
      <div>
        <h2 class="font-semibold"><%= card&.name || "Unknown Card" %></h2>
        <p class="text-sm text-gray-600"><%= card&.set&.name %></p>
        <p class="text-sm text-gray-500 mt-1">
          Currently in: <%= @item.collection.name %>
          <% if @item.storage_unit %>
            / <%= @item.storage_unit.name %>
          <% else %>
            (loose)
          <% end %>
        </p>
      </div>
    </div>

    <%= form_with model: @item, url: relocate_item_path(@item), method: :patch,
        data: {
          controller: "item-move",
          item_move_original_collection_value: @item.collection_id
        } do |f| %>

      <!-- Collection Selection -->
      <div class="mb-4">
        <%= f.label :collection_id, "Move to Collection", class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= f.select :collection_id,
            options_from_collection_for_select(@collections, :id, :name, @item.collection_id),
            {},
            {
              class: "w-full rounded-lg border-gray-300",
              data: { item_move_target: "collection", action: "change->item-move#collectionChanged" }
            } %>
      </div>

      <!-- Cross-collection warning -->
      <div class="hidden mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded-lg"
           data-item-move-target="warning">
        <p class="text-sm text-yellow-800">
          <strong>Note:</strong> Moving to a different collection will clear the storage unit.
          You can select a new storage unit below.
        </p>
      </div>

      <!-- Storage Unit Selection -->
      <div class="mb-6">
        <%= f.label :storage_unit_id, "Storage Unit", class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= f.select :storage_unit_id,
            options_for_select(
              [["No storage unit (loose)", ""]] + @current_storage_units.map { |u| [u.name, u.id] },
              @item.storage_unit_id
            ),
            {},
            {
              class: "w-full rounded-lg border-gray-300",
              data: { item_move_target: "storageUnit" }
            } %>
      </div>

      <!-- Actions -->
      <div class="flex justify-end gap-3">
        <%= link_to "Cancel", @item, class: "px-4 py-2 border rounded-lg hover:bg-gray-50" %>
        <%= f.submit "Move Item",
            class: "px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700" %>
      </div>
    <% end %>
  </div>
</div>
```

---

## Database Changes

**None required.** Uses existing `items` table with `collection_id` and `storage_unit_id` columns.

### Validation Enhancement (Optional)

Add validation to ensure storage unit belongs to the item's collection:

```ruby
# app/models/item.rb (addition)
class Item < ApplicationRecord
  validate :storage_unit_belongs_to_collection

  private

  def storage_unit_belongs_to_collection
    return unless storage_unit_id.present?
    return if storage_unit&.collection_id == collection_id

    errors.add(:storage_unit, "must belong to the same collection")
  end
end
```

---

## Test Requirements

### Model Specs

```ruby
# spec/models/item_spec.rb (additions)
require "rails_helper"

RSpec.describe Item, type: :model do
  describe "storage unit validation" do
    let(:collection1) { create(:collection) }
    let(:collection2) { create(:collection) }
    let(:storage_unit) { create(:storage_unit, collection: collection1) }

    it "allows storage unit from same collection" do
      item = build(:item, collection: collection1, storage_unit: storage_unit)
      expect(item).to be_valid
    end

    it "rejects storage unit from different collection" do
      item = build(:item, collection: collection2, storage_unit: storage_unit)
      expect(item).not_to be_valid
      expect(item.errors[:storage_unit]).to include("must belong to the same collection")
    end

    it "allows nil storage unit" do
      item = build(:item, collection: collection1, storage_unit: nil)
      expect(item).to be_valid
    end
  end
end
```

### Request Specs

```ruby
# spec/requests/items_spec.rb (additions)
require "rails_helper"

RSpec.describe "Item Organization", type: :request do
  let(:collection1) { create(:collection, name: "Main") }
  let(:collection2) { create(:collection, name: "Trade") }
  let(:storage_unit1) { create(:storage_unit, collection: collection1, name: "Box A") }
  let(:storage_unit2) { create(:storage_unit, collection: collection2, name: "Binder") }
  let(:card) { MTGJSON::Card.first }
  let!(:item) { create(:item, collection: collection1, storage_unit: storage_unit1, card_uuid: card.uuid) }

  describe "GET /items/:id/move" do
    it "returns successful response" do
      get move_item_path(item)
      expect(response).to have_http_status(:ok)
    end

    it "displays current location" do
      get move_item_path(item)
      expect(response.body).to include("Main")
      expect(response.body).to include("Box A")
    end

    it "lists all collections" do
      collection2 # ensure created
      get move_item_path(item)
      expect(response.body).to include("Main")
      expect(response.body).to include("Trade")
    end
  end

  describe "PATCH /items/:id/relocate" do
    context "moving within same collection" do
      let(:storage_unit1b) { create(:storage_unit, collection: collection1, name: "Box B") }

      it "moves to different storage unit" do
        patch relocate_item_path(item), params: {
          item: { collection_id: collection1.id, storage_unit_id: storage_unit1b.id }
        }

        item.reload
        expect(item.storage_unit).to eq(storage_unit1b)
        expect(item.collection).to eq(collection1)
      end

      it "removes from storage unit" do
        patch relocate_item_path(item), params: {
          item: { collection_id: collection1.id, storage_unit_id: "" }
        }

        expect(item.reload.storage_unit).to be_nil
      end
    end

    context "moving to different collection" do
      it "moves item to new collection" do
        patch relocate_item_path(item), params: {
          item: { collection_id: collection2.id }
        }

        item.reload
        expect(item.collection).to eq(collection2)
      end

      it "clears storage unit when moving collections" do
        patch relocate_item_path(item), params: {
          item: { collection_id: collection2.id }
        }

        expect(item.reload.storage_unit).to be_nil
      end

      it "assigns new storage unit in destination collection" do
        patch relocate_item_path(item), params: {
          item: { collection_id: collection2.id, storage_unit_id: storage_unit2.id }
        }

        item.reload
        expect(item.collection).to eq(collection2)
        expect(item.storage_unit).to eq(storage_unit2)
      end

      it "shows success message" do
        patch relocate_item_path(item), params: {
          item: { collection_id: collection2.id }
        }

        expect(flash[:notice]).to include("Trade")
      end
    end

    context "with invalid params" do
      it "rejects storage unit from wrong collection" do
        patch relocate_item_path(item), params: {
          item: { collection_id: collection1.id, storage_unit_id: storage_unit2.id }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
```

### System Specs

```ruby
# spec/system/item_organization_spec.rb
require "rails_helper"

RSpec.describe "Item Organization", type: :system do
  before do
    driven_by(:selenium_headless)
  end

  let(:collection1) { create(:collection, name: "Main Collection") }
  let(:collection2) { create(:collection, name: "Trade Binder") }
  let(:storage_unit1) { create(:storage_unit, collection: collection1, name: "Box A") }
  let(:storage_unit2) { create(:storage_unit, collection: collection1, name: "Box B") }
  let(:storage_unit3) { create(:storage_unit, collection: collection2, name: "Section 1") }
  let(:card) { MTGJSON::Card.first }
  let!(:item) { create(:item, collection: collection1, storage_unit: storage_unit1, card_uuid: card.uuid) }

  describe "moving within same collection" do
    before do
      storage_unit2 # ensure created
      visit move_item_path(item)
    end

    it "shows current location" do
      expect(page).to have_content("Main Collection")
      expect(page).to have_content("Box A")
    end

    it "moves to different storage unit" do
      select "Box B", from: "item[storage_unit_id]"
      click_button "Move Item"

      expect(page).to have_content("moved")
      expect(item.reload.storage_unit).to eq(storage_unit2)
    end

    it "removes from storage unit" do
      select "No storage unit (loose)", from: "item[storage_unit_id]"
      click_button "Move Item"

      expect(item.reload.storage_unit).to be_nil
    end
  end

  describe "moving to different collection" do
    before do
      collection2
      storage_unit3
      visit move_item_path(item)
    end

    it "shows warning when changing collection" do
      select "Trade Binder", from: "item[collection_id]"

      expect(page).to have_content("Moving to a different collection")
    end

    it "updates storage unit dropdown" do
      select "Trade Binder", from: "item[collection_id]"

      # Wait for AJAX
      expect(page).to have_select("item[storage_unit_id]", with_options: ["Section 1"])
    end

    it "moves to different collection" do
      select "Trade Binder", from: "item[collection_id]"
      click_button "Move Item"

      expect(item.reload.collection).to eq(collection2)
    end

    it "can select storage unit in new collection" do
      select "Trade Binder", from: "item[collection_id]"

      # Wait for dropdown to update
      sleep 0.5

      select "Section 1", from: "item[storage_unit_id]"
      click_button "Move Item"

      expect(item.reload.storage_unit).to eq(storage_unit3)
    end
  end

  describe "accessing move from item detail" do
    it "shows move link" do
      visit item_path(item)
      expect(page).to have_link("Move")
    end

    it "navigates to move page" do
      visit item_path(item)
      click_link "Move"

      expect(page).to have_current_path(move_item_path(item))
    end
  end

  describe "canceling move" do
    it "returns to item detail" do
      visit move_item_path(item)
      click_link "Cancel"

      expect(page).to have_current_path(item_path(item))
    end
  end
end
```

---

## UI/UX Specifications

### Move Form Layout

```
┌─────────────────────────────────────────────────────────────┐
│ ← Back to Item                                              │
├─────────────────────────────────────────────────────────────┤
│ Move Item                                                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───┐ Lightning Bolt                                       │
│  │IMG│ Limited Edition Alpha                                │
│  └───┘ Currently in: Main Collection / Box A                │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Move to Collection   [Main Collection              ▼]       │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ ⚠ Moving to a different collection will clear the      │ │
│ │   storage unit. Select a new one below.                │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ Storage Unit         [Box A                        ▼]       │
│                      Options:                               │
│                      - No storage unit (loose)              │
│                      - Box A                                │
│                      - Box B                                │
│                      - Deck Box 1                           │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                       [ Cancel ] [ Move ]   │
└─────────────────────────────────────────────────────────────┘
```

### Item Detail with Move Button

```
┌─────────────────────────────────────────────────────────────┐
│ Lightning Bolt                    [ Move ] [ Edit ] [Card]  │
├─────────────────────────────────────────────────────────────┤
│ ...                                                         │
└─────────────────────────────────────────────────────────────┘
```

### Quick Move (Dropdown on Item Card) - Future Enhancement

```
┌─────────────────────────────────┐
│ ┌───┐ Lightning Bolt       [⋮] │
│ │IMG│ LEA · NM                 │
│ └───┘ 📦 Box A            [▼]  │
│        ├── No storage unit     │
│        ├── Box A ✓             │
│        ├── Box B               │
│        └── Deck Box 1          │
└─────────────────────────────────┘
```

---

## Dependencies

- **Phase 2.3**: Item Detail/Edit (navigation, edit patterns)
- **StorageUnit model**: For storage unit dropdowns
- **Stimulus**: For dynamic dropdown updates

---

## Definition of Done

- [ ] Move item form accessible from item detail page
- [ ] Can move item to different storage unit (same collection)
- [ ] Can remove item from storage unit (make loose)
- [ ] Can move item to different collection
- [ ] Storage unit dropdown updates when collection changes
- [ ] Warning shown when moving between collections
- [ ] Storage unit cleared when moving to different collection
- [ ] Can select new storage unit in destination collection
- [ ] Validation prevents storage unit from wrong collection
- [ ] Success message indicates destination
- [ ] Cancel returns to item detail
- [ ] Stimulus controller for dynamic updates
- [ ] All model specs pass
- [ ] All request specs pass
- [ ] All system specs pass
- [ ] Responsive design
- [ ] Accessible form
- [ ] `bin/rubocop --fix` passes
- [ ] `bin/rspec` passes

---

## Future Enhancements (Not in MVP)

- Bulk move multiple items at once
- Quick move dropdown on item card
- Move history/log
- Drag and drop interface
- Move to new storage unit (create on the fly)
- Keyboard shortcuts for common moves
- Undo move action
