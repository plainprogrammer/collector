# Phase 2.5: Delete Items

## Feature Overview

Enable users to permanently remove items from their collection. This feature includes confirmation dialogs to prevent accidental deletion and clear feedback about what is being deleted.

**Priority**: High (essential for collection management)
**Dependencies**: Phase 2.2, Phase 2.3
**Estimated Complexity**: Low

---

## User Stories

### US-2.5.1: Delete Single Item
**As a** collector
**I want to** delete an item from my collection
**So that** I can remove cards I no longer own

### US-2.5.2: Confirm Before Deletion
**As a** collector
**I want to** confirm before deleting an item
**So that** I don't accidentally remove cards

### US-2.5.3: See What's Being Deleted
**As a** collector
**I want to** see the card name and set when confirming deletion
**So that** I know exactly what I'm removing

### US-2.5.4: Receive Deletion Confirmation
**As a** collector
**I want to** see confirmation that the item was deleted
**So that** I know the action was successful

---

## Acceptance Criteria

### AC-2.5.1: Delete from Item Detail Page

```gherkin
Feature: Delete from Item Detail

  Scenario: Delete button visible
    Given I am viewing an item detail page
    Then I should see a "Delete" button or link

  Scenario: Delete button styling
    Given I am viewing an item detail page
    Then the delete button should be styled to indicate danger
    And it should be visually distinct from other actions

  Scenario: Confirmation dialog
    Given I am viewing an item detail page
    When I click the "Delete" button
    Then I should see a confirmation dialog
    And the dialog should include the card name
    And I should be able to cancel or confirm

  Scenario: Cancel deletion
    Given I see the delete confirmation dialog
    When I click "Cancel"
    Then the item should not be deleted
    And I should remain on the item detail page

  Scenario: Confirm deletion
    Given I see the delete confirmation dialog
    When I click "Delete" to confirm
    Then the item should be permanently removed
    And I should be redirected to the collection items list
    And I should see a success message
```

### AC-2.5.2: Delete from Item List (Optional)

```gherkin
Feature: Delete from Item List

  Scenario: Quick delete option
    Given I am viewing the items list
    Then each item may have a delete option (icon or menu)

  Scenario: Confirmation before delete
    Given I click delete on an item in the list
    Then I should see a confirmation before the item is deleted
```

### AC-2.5.3: Confirmation Message Content

```gherkin
Feature: Deletion Confirmation Message

  Scenario: Show card name in confirmation
    Given I am deleting a "Lightning Bolt" item
    When I see the confirmation dialog
    Then I should see "Delete Lightning Bolt?"
    Or "Are you sure you want to delete this Lightning Bolt?"

  Scenario: Show set information
    Given I am deleting a "Lightning Bolt" from "LEA"
    When I see the confirmation dialog
    Then I should see the set name or code

  Scenario: Warn about permanence
    When I see the confirmation dialog
    Then I should see a warning that this action cannot be undone
```

### AC-2.5.4: Post-Deletion Behavior

```gherkin
Feature: After Deletion

  Scenario: Redirect after deletion
    Given I confirm deletion of an item
    Then I should be redirected to the collection items list
    And I should not be on a 404 page

  Scenario: Success message
    Given I successfully delete an item
    Then I should see a message like "Item deleted"
    Or "Lightning Bolt removed from collection"

  Scenario: Item count updated
    Given my collection had 10 items
    When I delete one item
    Then the items list should show "9 items"
```

### AC-2.5.5: Edge Cases

```gherkin
Feature: Deletion Edge Cases

  Scenario: Delete last item in collection
    Given my collection has only 1 item
    When I delete that item
    Then I should see the empty collection state
    And I should see "No items in this collection"

  Scenario: Delete item with storage unit
    Given an item is stored in "Box A"
    When I delete the item
    Then the item should be removed
    And "Box A" should still exist
    And the storage unit item count should decrease

  Scenario: Item not found (already deleted)
    Given an item has already been deleted
    When I try to delete it again
    Then I should see a 404 or "Item not found" error
```

---

## Technical Implementation

### Routes

```ruby
# config/routes.rb
# Items are nested under collections with shallow routing
resources :collections do
  resources :items, shallow: true
  resources :storage_units, shallow: true
end
```

**Route for this feature (shallow):**
- `DELETE /items/:id` → `items#destroy`

### Controller

```ruby
# app/controllers/items_controller.rb (additions)
class ItemsController < ApplicationController
  before_action :set_item, only: [:show, :edit, :update, :destroy]

  def destroy
    collection = @item.collection
    card_name = @item.card&.name || "Item"

    @item.destroy!

    redirect_to collection_items_path(collection),
                notice: "#{card_name} removed from collection"
  end

  private

  def set_item
    @item = Item.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to collections_path, alert: "Item not found"
  end
end
```

### View Integration

The delete button is typically placed on the item detail page:

```erb
<%# app/views/items/show.html.erb (addition) %>

<!-- Delete button with Turbo confirmation -->
<%= button_to "Delete Item", @item,
    method: :delete,
    class: "text-red-600 hover:text-red-800 font-medium",
    form: {
      data: {
        turbo_confirm: "Are you sure you want to delete #{@item.card&.name || 'this item'}? This action cannot be undone."
      }
    } %>
```

### Custom Confirmation Dialog (Optional Enhancement)

For a better UX, consider a custom Stimulus-powered confirmation:

```javascript
// app/javascript/controllers/confirm_delete_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "itemName"]
  static values = {
    name: String,
    set: String
  }

  open(event) {
    event.preventDefault()

    // Update dialog content
    this.itemNameTarget.textContent = this.nameValue

    // Show dialog
    this.dialogTarget.showModal()
  }

  cancel() {
    this.dialogTarget.close()
  }

  confirm() {
    // Submit the delete form
    this.element.querySelector("form").requestSubmit()
  }
}
```

```erb
<%# Custom confirmation dialog %>
<div data-controller="confirm-delete"
     data-confirm-delete-name-value="<%= @item.card&.name %>"
     data-confirm-delete-set-value="<%= @item.card&.set&.name %>">

  <%= button_to "Delete Item",
      @item,
      method: :delete,
      class: "text-red-600",
      data: { action: "click->confirm-delete#open" },
      form: { class: "inline", data: { turbo: false } } %>

  <dialog data-confirm-delete-target="dialog"
          class="rounded-lg p-6 backdrop:bg-black backdrop:bg-opacity-50">
    <h2 class="text-lg font-bold mb-4">Delete Item?</h2>
    <p class="mb-4">
      Are you sure you want to delete
      <strong data-confirm-delete-target="itemName"></strong>?
    </p>
    <p class="text-sm text-gray-500 mb-6">
      This action cannot be undone.
    </p>
    <div class="flex justify-end gap-3">
      <button type="button"
              data-action="confirm-delete#cancel"
              class="px-4 py-2 border rounded-lg">
        Cancel
      </button>
      <button type="button"
              data-action="confirm-delete#confirm"
              class="px-4 py-2 bg-red-600 text-white rounded-lg">
        Delete
      </button>
    </div>
  </dialog>
</div>
```

### Turbo Stream Response (Optional Enhancement)

For deleting from the list view without full page reload:

```ruby
# app/controllers/items_controller.rb
def destroy
  collection = @item.collection
  card_name = @item.card&.name || "Item"

  @item.destroy!

  respond_to do |format|
    format.html {
      redirect_to collection_items_path(collection),
                  notice: "#{card_name} removed from collection"
    }
    format.turbo_stream {
      render turbo_stream: [
        turbo_stream.remove(@item),
        turbo_stream.update("item-count", partial: "items/count", locals: { collection: collection }),
        turbo_stream.update("flash", partial: "shared/flash", locals: { notice: "#{card_name} removed" })
      ]
    }
  end
end
```

---

## Database Changes

**None required.** Uses existing `Item#destroy` method.

---

## Test Requirements

### Request Specs

```ruby
# spec/requests/items_spec.rb (additions)
require "rails_helper"

RSpec.describe "Item Deletion", type: :request do
  let(:collection) { create(:collection) }
  let(:card) { MTGJSON::Card.first }
  let!(:item) { create(:item, collection: collection, card_uuid: card.uuid) }

  describe "DELETE /items/:id" do
    it "deletes the item" do
      expect {
        delete item_path(item)
      }.to change(Item, :count).by(-1)
    end

    it "redirects to collection items" do
      delete item_path(item)
      expect(response).to redirect_to(collection_items_path(collection))
    end

    it "shows success message" do
      delete item_path(item)
      follow_redirect!
      expect(response.body).to include("removed")
    end

    it "includes card name in success message" do
      delete item_path(item)
      expect(flash[:notice]).to include(card.name)
    end

    context "when item has storage unit" do
      let(:storage_unit) { create(:storage_unit, collection: collection) }
      let!(:item) { create(:item, collection: collection, storage_unit: storage_unit, card_uuid: card.uuid) }

      it "does not delete the storage unit" do
        expect {
          delete item_path(item)
        }.not_to change(StorageUnit, :count)
      end
    end

    context "when item does not exist" do
      it "handles gracefully" do
        delete item_path(id: 99999)
        expect(response).to redirect_to(collections_path)
        expect(flash[:alert]).to include("not found")
      end
    end

    context "with turbo stream request" do
      it "returns turbo stream response" do
        delete item_path(item), headers: { Accept: "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end
  end
end
```

### System Specs

```ruby
# spec/system/delete_item_spec.rb
require "rails_helper"

RSpec.describe "Delete Item", type: :system do
  before do
    driven_by(:selenium_headless)
  end

  let(:collection) { create(:collection, name: "My Collection") }
  let(:card) { MTGJSON::Card.first }
  let!(:item) { create(:item, collection: collection, card_uuid: card.uuid) }

  describe "deleting from item detail page" do
    before { visit item_path(item) }

    it "shows delete button" do
      expect(page).to have_button("Delete")
    end

    it "shows confirmation dialog" do
      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_current_path(collection_items_path(collection))
    end

    it "can cancel deletion" do
      dismiss_confirm do
        click_button "Delete"
      end

      expect(page).to have_current_path(item_path(item))
      expect(Item.exists?(item.id)).to be true
    end

    it "deletes item on confirm" do
      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_content("removed")
      expect(Item.exists?(item.id)).to be false
    end

    it "redirects to collection items" do
      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_current_path(collection_items_path(collection))
    end

    it "shows success message with card name" do
      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_content(card.name)
    end
  end

  describe "deleting last item in collection" do
    it "shows empty state after deletion" do
      visit item_path(item)

      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_content("No items")
    end
  end

  describe "item count update" do
    let!(:item2) { create(:item, collection: collection, card_uuid: card.uuid) }

    it "updates item count after deletion" do
      visit item_path(item)

      expect(collection.items.count).to eq(2)

      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_content("1 item")
    end
  end
end
```

---

## UI/UX Specifications

### Delete Button on Item Detail

```
┌─────────────────────────────────────────────────────────────┐
│ Lightning Bolt                    [ Move ] [ Edit ] [Card]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ... item details ...                                        │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ ← Back to Items                         [ Delete Item ]     │
│                                         ^^^^^^^^^^^^        │
│                                         Red text, right     │
│                                         aligned              │
└─────────────────────────────────────────────────────────────┘
```

### Browser Confirmation Dialog

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   Are you sure you want to delete Lightning Bolt?           │
│   This action cannot be undone.                             │
│                                                             │
│                              [ Cancel ]  [ OK ]             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Custom Confirmation Dialog (Optional Enhancement)

```
┌─────────────────────────────────────────────────────────────┐
│ Delete Item?                                            [×] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Are you sure you want to delete:                           │
│                                                             │
│  ┌───┐ Lightning Bolt                                       │
│  │IMG│ Limited Edition Alpha                                │
│  └───┘ Near Mint · Non-foil                                 │
│                                                             │
│  ⚠ This action cannot be undone.                            │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                              [ Cancel ]  [ Delete Item ]    │
│                                          ^^^^^^^^^^^^^^^    │
│                                          Red background     │
└─────────────────────────────────────────────────────────────┘
```

### Success Message

```
┌─────────────────────────────────────────────────────────────┐
│ ✓ Lightning Bolt removed from collection              [×]  │
└─────────────────────────────────────────────────────────────┘
```

### Delete Button Styling

```css
/* Tailwind classes for delete button */
.delete-button {
  @apply text-red-600 hover:text-red-800 hover:bg-red-50
         px-3 py-1.5 rounded-lg text-sm font-medium
         transition-colors;
}

/* Or for a more prominent button */
.delete-button-prominent {
  @apply bg-red-600 text-white hover:bg-red-700
         px-4 py-2 rounded-lg font-medium
         focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2;
}
```

---

## Accessibility

- Delete button has clear, descriptive text
- Confirmation dialog is focusable and keyboard accessible
- Dialog traps focus while open
- Escape key closes dialog
- Screen readers announce confirmation message
- Color is not the only indicator (icon + text)

---

## Dependencies

- **Phase 2.2**: Item List (redirect destination)
- **Phase 2.3**: Item Detail (delete button location)
- **Turbo**: For confirmation dialogs and optional streaming

---

## Definition of Done

- [ ] `ItemsController#destroy` action implemented
- [ ] Route configured for `DELETE /items/:id`
- [ ] Delete button visible on item detail page
- [ ] Button styled to indicate danger (red)
- [ ] Browser or custom confirmation dialog
- [ ] Confirmation includes card name
- [ ] Warning about permanent action
- [ ] Cancel returns to item without deleting
- [ ] Confirm deletes item permanently
- [ ] Redirect to collection items list
- [ ] Success flash message with card name
- [ ] Item count updates in list view
- [ ] Handles already-deleted item gracefully
- [ ] Does not delete associated storage unit
- [ ] Empty collection shows empty state after last delete
- [ ] All request specs pass
- [ ] All system specs pass
- [ ] Accessible confirmation dialog
- [ ] `bin/rubocop --fix` passes
- [ ] `bin/rspec` passes

---

## Future Enhancements (Not in MVP)

- Bulk delete multiple items
- Soft delete with undo option
- Delete from list view (Turbo Stream)
- Trash/recycle bin
- Delete confirmation shows item value
- Require additional confirmation for high-value items
- Audit log of deletions
