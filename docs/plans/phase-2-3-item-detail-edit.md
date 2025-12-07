# Phase 2.3: Item Detail & Edit

## Feature Overview

Display comprehensive item details and allow editing of item attributes. This view shows both the MTGJSON card data (read-only) and the user's item-specific data (editable), providing full visibility and control over collection items.

**Priority**: Critical (core MVP functionality)
**Dependencies**: Phase 2.1, Phase 2.2
**Estimated Complexity**: Medium

---

## User Stories

### US-2.3.1: View Item Details
**As a** collector
**I want to** see all details about an item in my collection
**So that** I can understand its complete information

### US-2.3.2: View Associated Card Data
**As a** collector
**I want to** see the card's MTGJSON data alongside my item
**So that** I can reference the card's rules text, legalities, etc.

### US-2.3.3: Edit Item Attributes
**As a** collector
**I want to** update my item's condition, finish, storage location, etc.
**So that** I can keep my collection data accurate

### US-2.3.4: View Acquisition History
**As a** collector
**I want to** see when and how I acquired this item
**So that** I can track my collection history

### US-2.3.5: Navigate to Related Content
**As a** collector
**I want to** navigate to the card detail, collection, or storage unit
**So that** I can explore related information

---

## Acceptance Criteria

### AC-2.3.1: Item Detail Page

```gherkin
Feature: Item Detail Page

  Scenario: Display item information
    Given I have an item in my collection
    When I visit the item detail page
    Then I should see:
      | section         | information                    |
      | Card Info       | Name, image, type, rules text  |
      | Item Attributes | Condition, finish, language    |
      | Storage         | Collection name, storage unit  |
      | Special Flags   | Signed, altered, misprint      |
      | Acquisition     | Date, price, notes             |

  Scenario: Display card image
    When I view an item detail page
    Then I should see the card image (from Scryfall)
    And the image should be larger than in the list view

  Scenario: Item not found
    When I visit an item detail page with invalid ID
    Then I should see a 404 error
    Or I should be redirected with an error message
```

### AC-2.3.2: Card Data Display (Read-Only)

```gherkin
Feature: Card Data Display

  Scenario: Display card details
    Given I am viewing an item detail page
    Then I should see the card's:
      | field       | example                        |
      | name        | "Lightning Bolt"               |
      | mana cost   | "{R}"                          |
      | type        | "Instant"                      |
      | rules text  | "Lightning Bolt deals 3..."    |
      | set         | "Limited Edition Alpha (LEA)"  |
      | rarity      | "Common"                       |

  Scenario: Link to full card details
    Given I am viewing an item detail page
    When I click "View Full Card Details"
    Then I should be on the MTGJSON card detail page

  Scenario: Card data is not editable
    Given I am viewing an item detail page
    Then the card data section should not have edit controls
    And there should be a note that card data is from MTGJSON
```

### AC-2.3.3: Item Attributes Display

```gherkin
Feature: Item Attributes Display

  Scenario: Display condition
    Given my item has condition "lightly_played"
    When I view the item detail page
    Then I should see "Lightly Played (LP)"

  Scenario: Display finish
    Given my item has finish "traditional_foil"
    When I view the item detail page
    Then I should see "Traditional Foil"

  Scenario: Display language
    Given my item has language "ja"
    When I view the item detail page
    Then I should see "Japanese"

  Scenario: Display special flags
    Given my item is signed and altered
    When I view the item detail page
    Then I should see "Signed: Yes"
    And I should see "Altered: Yes"
    And I should see "Misprint: No"
```

### AC-2.3.4: Storage Information

```gherkin
Feature: Storage Information

  Scenario: Display storage unit
    Given my item is stored in "Deck Box Alpha"
    When I view the item detail page
    Then I should see "Storage: Deck Box Alpha"
    And the storage unit name should link to its page

  Scenario: Display loose item
    Given my item has no storage unit
    When I view the item detail page
    Then I should see "Storage: Loose (no storage unit)"

  Scenario: Display collection
    Given my item is in collection "Main Collection"
    When I view the item detail page
    Then I should see "Collection: Main Collection"
    And the collection name should link to its page
```

### AC-2.3.5: Acquisition Information

```gherkin
Feature: Acquisition Information

  Scenario: Display acquisition date
    Given my item was acquired on "2024-01-15"
    When I view the item detail page
    Then I should see "Acquired: January 15, 2024"

  Scenario: Display acquisition price
    Given my item was acquired for $25.50
    When I view the item detail page
    Then I should see "Price Paid: $25.50"

  Scenario: Display notes
    Given my item has notes "From GP Vegas 2024"
    When I view the item detail page
    Then I should see the notes displayed

  Scenario: No acquisition info
    Given my item has no acquisition information
    When I view the item detail page
    Then I should see "Not recorded" for date and price
```

### AC-2.3.6: Edit Item Form

```gherkin
Feature: Edit Item Form

  Scenario: Access edit form
    Given I am viewing an item detail page
    When I click "Edit"
    Then I should see the edit form
    And current values should be pre-filled

  Scenario: Edit condition
    Given I am editing an item
    When I change condition to "Moderately Played"
    And I save the changes
    Then the item should show "Moderately Played"

  Scenario: Edit finish
    Given I am editing an item
    When I change finish to "Etched Foil"
    And I save the changes
    Then the item should show "Etched Foil"

  Scenario: Edit storage unit
    Given I am editing an item
    And my collection has storage units "Box A" and "Box B"
    When I change storage unit to "Box B"
    And I save the changes
    Then the item should be in "Box B"

  Scenario: Remove from storage unit
    Given my item is in storage unit "Box A"
    When I edit and select "No storage unit (loose)"
    And I save the changes
    Then the item should show "Loose"

  Scenario: Edit language
    Given I am editing an item
    When I change language to "German"
    And I save the changes
    Then the item should show "German"

  Scenario: Toggle special flags
    Given I am editing an item that is not signed
    When I check "Signed"
    And I save the changes
    Then the item should show "Signed: Yes"

  Scenario: Edit acquisition information
    Given I am editing an item
    When I enter acquisition date "2024-06-01"
    And I enter acquisition price "15.00"
    And I enter notes "Trade at LGS"
    And I save the changes
    Then the item should show the updated acquisition info

  Scenario: Validation errors
    Given I am editing an item
    When I enter an invalid language code "xxx"
    And I try to save
    Then I should see a validation error
    And the form should remain open with my changes
```

### AC-2.3.7: Inline Edit (Optional Enhancement)

```gherkin
Feature: Inline Edit

  Scenario: Quick edit without full form
    Given I am viewing an item detail page
    When I click the condition badge
    Then I should see a dropdown to change condition
    And selecting a new value should save immediately
```

### AC-2.3.8: Navigation

```gherkin
Feature: Item Detail Navigation

  Scenario: Navigate to collection
    Given I am viewing an item detail page
    When I click the collection name
    Then I should be on the collection page

  Scenario: Navigate to storage unit
    Given I am viewing an item with a storage unit
    When I click the storage unit name
    Then I should be on the storage unit page

  Scenario: Navigate to card detail
    Given I am viewing an item detail page
    When I click "View Card"
    Then I should be on the MTGJSON card detail page

  Scenario: Back to collection items
    Given I am viewing an item detail page
    When I click "Back to Items"
    Then I should be on the collection items list
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

**Routes for this feature (shallow):**
- `GET /items/:id` → `items#show`
- `GET /items/:id/edit` → `items#edit`
- `PATCH/PUT /items/:id` → `items#update`

### Controller

```ruby
# app/controllers/items_controller.rb (additions)
class ItemsController < ApplicationController
  before_action :set_item, only: [:show, :edit, :update, :destroy]

  def show
    @card = @item.card
  end

  def edit
    @card = @item.card
    @storage_units = @item.collection.storage_units.order(:name)
  end

  def update
    if @item.update(item_params)
      redirect_to @item, notice: "Item updated successfully"
    else
      @card = @item.card
      @storage_units = @item.collection.storage_units.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_item
    @item = Item.includes(:collection, :storage_unit).find(params[:id])
  end

  def item_params
    params.require(:item).permit(
      :storage_unit_id,
      :condition,
      :finish,
      :language,
      :signed,
      :altered,
      :misprint,
      :acquisition_date,
      :acquisition_price,
      :grading_service,
      :grading_score,
      :notes
    )
  end
end
```

### Views

```
app/views/items/
├── show.html.erb           # Item detail page
├── edit.html.erb           # Edit item page
├── _form.html.erb          # Form partial (shared with new)
├── _card_section.html.erb  # Card info section
├── _item_attributes.html.erb  # Item attributes section
└── _acquisition_section.html.erb  # Acquisition info section
```

### Item Show View

```erb
<%# app/views/items/show.html.erb %>
<% content_for :title, "#{@card&.name || 'Item'} - #{@item.collection.name}" %>

<article class="max-w-4xl mx-auto">
  <nav class="mb-6 text-sm text-gray-500">
    <%= link_to "Collections", collections_path %> /
    <%= link_to @item.collection.name, @item.collection %> /
    <%= link_to "Items", collection_items_path(@item.collection) %>
  </nav>

  <div class="bg-white rounded-lg shadow-sm border overflow-hidden">
    <!-- Header with actions -->
    <header class="flex items-center justify-between p-6 border-b bg-gray-50">
      <h1 class="text-2xl font-bold text-gray-900">
        <%= @card&.name || "Unknown Card" %>
      </h1>
      <div class="flex gap-2">
        <%= link_to "Edit", edit_item_path(@item),
            class: "px-4 py-2 bg-white border rounded-lg hover:bg-gray-50" %>
        <%= link_to "View Card", card_path(@card.uuid),
            class: "px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700" if @card %>
      </div>
    </header>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 p-6">
      <!-- Card Image -->
      <div class="md:col-span-1">
        <% if @card %>
          <%= card_image_tag(@card, size: :normal, class: "w-full rounded-lg shadow") %>
        <% else %>
          <div class="aspect-[5/7] bg-gray-200 rounded-lg flex items-center justify-center">
            <span class="text-gray-500">Image not available</span>
          </div>
        <% end %>
      </div>

      <!-- Item Details -->
      <div class="md:col-span-2 space-y-6">
        <!-- Card Info (Read-only) -->
        <%= render "card_section", card: @card %>

        <!-- Item Attributes -->
        <%= render "item_attributes", item: @item %>

        <!-- Storage Info -->
        <section>
          <h2 class="text-lg font-semibold text-gray-900 mb-3">Storage</h2>
          <dl class="grid grid-cols-2 gap-4">
            <div>
              <dt class="text-sm text-gray-500">Collection</dt>
              <dd>
                <%= link_to @item.collection.name, @item.collection,
                    class: "text-indigo-600 hover:underline" %>
              </dd>
            </div>
            <div>
              <dt class="text-sm text-gray-500">Storage Unit</dt>
              <dd>
                <% if @item.storage_unit %>
                  <%= link_to @item.storage_unit.name, @item.storage_unit,
                      class: "text-indigo-600 hover:underline" %>
                <% else %>
                  <span class="text-gray-400">Loose (no storage unit)</span>
                <% end %>
              </dd>
            </div>
          </dl>
        </section>

        <!-- Acquisition Info -->
        <%= render "acquisition_section", item: @item %>
      </div>
    </div>

    <!-- Timestamps -->
    <footer class="px-6 py-4 bg-gray-50 border-t text-sm text-gray-500">
      Added <%= time_ago_in_words(@item.created_at) %> ago
      <% if @item.updated_at != @item.created_at %>
        · Updated <%= time_ago_in_words(@item.updated_at) %> ago
      <% end %>
    </footer>
  </div>

  <!-- Actions -->
  <div class="mt-6 flex justify-between">
    <%= link_to "← Back to Items", collection_items_path(@item.collection),
        class: "text-indigo-600 hover:text-indigo-800" %>

    <%= button_to "Delete Item", @item,
        method: :delete,
        class: "text-red-600 hover:text-red-800",
        form: { data: { turbo_confirm: "Are you sure you want to delete this item?" } } %>
  </div>
</article>
```

### Item Attributes Partial

```erb
<%# app/views/items/_item_attributes.html.erb %>
<section>
  <h2 class="text-lg font-semibold text-gray-900 mb-3">Item Attributes</h2>
  <dl class="grid grid-cols-2 gap-4">
    <div>
      <dt class="text-sm text-gray-500">Condition</dt>
      <dd>
        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-sm font-medium <%= condition_badge_class(item.condition) %>">
          <%= condition_display_name(item.condition) %>
        </span>
      </dd>
    </div>

    <div>
      <dt class="text-sm text-gray-500">Finish</dt>
      <dd>
        <span class="<%= finish_badge_class(item.finish) %> px-2.5 py-0.5 rounded-full text-sm font-medium">
          <%= item.finish.humanize.titleize %>
        </span>
      </dd>
    </div>

    <div>
      <dt class="text-sm text-gray-500">Language</dt>
      <dd><%= language_name(item.language) %></dd>
    </div>

    <div>
      <dt class="text-sm text-gray-500">Signed</dt>
      <dd><%= item.signed ? "Yes" : "No" %></dd>
    </div>

    <div>
      <dt class="text-sm text-gray-500">Altered</dt>
      <dd><%= item.altered ? "Yes" : "No" %></dd>
    </div>

    <div>
      <dt class="text-sm text-gray-500">Misprint</dt>
      <dd><%= item.misprint ? "Yes" : "No" %></dd>
    </div>

    <% if item.grading_service.present? %>
      <div>
        <dt class="text-sm text-gray-500">Grading</dt>
        <dd><%= item.grading_service %> - <%= item.grading_score %></dd>
      </div>
    <% end %>
  </dl>
</section>
```

### Edit Form

```erb
<%# app/views/items/edit.html.erb %>
<% content_for :title, "Edit Item" %>

<div class="max-w-2xl mx-auto">
  <nav class="mb-6">
    <%= link_to "← Back to Item", @item, class: "text-indigo-600 hover:text-indigo-800" %>
  </nav>

  <h1 class="text-2xl font-bold mb-6">Edit Item</h1>

  <div class="bg-white rounded-lg shadow-sm border p-6">
    <!-- Card Preview (read-only) -->
    <div class="flex gap-4 mb-6 pb-6 border-b">
      <% if @card %>
        <%= card_image_tag(@card, size: :small, class: "w-20 rounded") %>
      <% end %>
      <div>
        <h2 class="font-semibold"><%= @card&.name || "Unknown Card" %></h2>
        <p class="text-sm text-gray-600"><%= @card&.set&.name %></p>
        <p class="text-xs text-gray-400 mt-1">Card data cannot be edited</p>
      </div>
    </div>

    <%= form_with model: @item, local: true, class: "space-y-6" do |f| %>
      <% if @item.errors.any? %>
        <div class="bg-red-50 border border-red-200 rounded-lg p-4" data-testid="error-message">
          <h3 class="text-red-800 font-medium">Please correct the following errors:</h3>
          <ul class="mt-2 text-sm text-red-700 list-disc list-inside">
            <% @item.errors.full_messages.each do |message| %>
              <li><%= message %></li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <!-- Storage Unit -->
      <div>
        <%= f.label :storage_unit_id, "Storage Unit", class: "block text-sm font-medium text-gray-700" %>
        <%= f.select :storage_unit_id,
            options_for_select(
              [["No storage unit (loose)", nil]] + @storage_units.map { |u| [u.name, u.id] },
              @item.storage_unit_id
            ),
            {},
            class: "mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" %>
      </div>

      <!-- Condition -->
      <div>
        <%= f.label :condition, class: "block text-sm font-medium text-gray-700" %>
        <%= f.select :condition,
            condition_options,
            {},
            class: "mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" %>
      </div>

      <!-- Finish -->
      <div>
        <%= f.label :finish, class: "block text-sm font-medium text-gray-700" %>
        <%= f.select :finish,
            finish_options,
            {},
            class: "mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" %>
      </div>

      <!-- Language -->
      <div>
        <%= f.label :language, class: "block text-sm font-medium text-gray-700" %>
        <%= f.select :language,
            language_options,
            {},
            class: "mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" %>
      </div>

      <!-- Special Flags -->
      <fieldset class="space-y-2">
        <legend class="text-sm font-medium text-gray-700">Special Attributes</legend>
        <div class="flex gap-6">
          <label class="flex items-center gap-2">
            <%= f.check_box :signed, class: "rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" %>
            <span class="text-sm text-gray-700">Signed</span>
          </label>
          <label class="flex items-center gap-2">
            <%= f.check_box :altered, class: "rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" %>
            <span class="text-sm text-gray-700">Altered</span>
          </label>
          <label class="flex items-center gap-2">
            <%= f.check_box :misprint, class: "rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" %>
            <span class="text-sm text-gray-700">Misprint</span>
          </label>
        </div>
      </fieldset>

      <!-- Acquisition Information -->
      <fieldset class="space-y-4">
        <legend class="text-sm font-medium text-gray-700">Acquisition Information</legend>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <%= f.label :acquisition_date, "Date Acquired", class: "block text-sm font-medium text-gray-700" %>
            <%= f.date_field :acquisition_date,
                class: "mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" %>
          </div>
          <div>
            <%= f.label :acquisition_price, "Price Paid", class: "block text-sm font-medium text-gray-700" %>
            <div class="mt-1 relative rounded-lg shadow-sm">
              <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <span class="text-gray-500 sm:text-sm">$</span>
              </div>
              <%= f.number_field :acquisition_price,
                  step: 0.01,
                  min: 0,
                  class: "block w-full pl-7 rounded-lg border-gray-300 focus:border-indigo-500 focus:ring-indigo-500" %>
            </div>
          </div>
        </div>

        <div>
          <%= f.label :notes, class: "block text-sm font-medium text-gray-700" %>
          <%= f.text_area :notes,
              rows: 3,
              class: "mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500",
              placeholder: "Where you got it, who you traded with, etc." %>
        </div>
      </fieldset>

      <!-- Grading (if applicable) -->
      <fieldset class="space-y-4">
        <legend class="text-sm font-medium text-gray-700">Professional Grading (optional)</legend>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <%= f.label :grading_service, "Grading Service", class: "block text-sm font-medium text-gray-700" %>
            <%= f.text_field :grading_service,
                placeholder: "PSA, BGS, CGC, etc.",
                class: "mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" %>
          </div>
          <div>
            <%= f.label :grading_score, "Grade", class: "block text-sm font-medium text-gray-700" %>
            <%= f.number_field :grading_score,
                step: 0.5,
                min: 0,
                max: 10,
                class: "mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" %>
          </div>
        </div>
      </fieldset>

      <!-- Submit -->
      <div class="flex justify-end gap-3 pt-4 border-t">
        <%= link_to "Cancel", @item, class: "px-4 py-2 border rounded-lg hover:bg-gray-50" %>
        <%= f.submit "Save Changes",
            class: "px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" %>
      </div>
    <% end %>
  </div>
</div>
```

---

## Database Changes

**None required.** Uses existing `items` table schema.

---

## Test Requirements

### Request Specs

```ruby
# spec/requests/items_spec.rb (additions)
require "rails_helper"

RSpec.describe "Items", type: :request do
  let(:collection) { create(:collection) }
  let(:card) { MTGJSON::Card.first }
  let!(:item) { create(:item, collection: collection, card_uuid: card.uuid) }

  describe "GET /items/:id" do
    it "returns successful response" do
      get item_path(item)
      expect(response).to have_http_status(:ok)
    end

    it "displays card name" do
      get item_path(item)
      expect(response.body).to include(card.name)
    end

    it "displays item condition" do
      get item_path(item)
      expect(response.body).to include("Near Mint")
    end

    it "displays collection name" do
      get item_path(item)
      expect(response.body).to include(collection.name)
    end

    context "with storage unit" do
      let(:storage_unit) { create(:storage_unit, collection: collection, name: "Box A") }
      let!(:item) { create(:item, collection: collection, card_uuid: card.uuid, storage_unit: storage_unit) }

      it "displays storage unit name" do
        get item_path(item)
        expect(response.body).to include("Box A")
      end
    end

    context "when item not found" do
      it "returns 404" do
        get item_path(id: 99999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /items/:id/edit" do
    it "returns successful response" do
      get edit_item_path(item)
      expect(response).to have_http_status(:ok)
    end

    it "displays current values" do
      get edit_item_path(item)
      expect(response.body).to include(item.condition.humanize)
    end

    it "lists storage units from same collection" do
      storage_unit = create(:storage_unit, collection: collection, name: "Box A")
      get edit_item_path(item)
      expect(response.body).to include("Box A")
    end
  end

  describe "PATCH /items/:id" do
    context "with valid parameters" do
      let(:new_params) do
        { item: { condition: "lightly_played", finish: "traditional_foil" } }
      end

      it "updates the item" do
        patch item_path(item), params: new_params
        item.reload
        expect(item.condition).to eq("lightly_played")
        expect(item.finish).to eq("traditional_foil")
      end

      it "redirects to item show" do
        patch item_path(item), params: new_params
        expect(response).to redirect_to(item_path(item))
      end

      it "shows success message" do
        patch item_path(item), params: new_params
        follow_redirect!
        expect(response.body).to include("updated")
      end
    end

    context "updating storage unit" do
      let(:storage_unit) { create(:storage_unit, collection: collection) }

      it "assigns to storage unit" do
        patch item_path(item), params: { item: { storage_unit_id: storage_unit.id } }
        expect(item.reload.storage_unit).to eq(storage_unit)
      end

      it "removes from storage unit" do
        item.update!(storage_unit: storage_unit)
        patch item_path(item), params: { item: { storage_unit_id: "" } }
        expect(item.reload.storage_unit).to be_nil
      end
    end

    context "updating special flags" do
      it "sets signed flag" do
        patch item_path(item), params: { item: { signed: true } }
        expect(item.reload.signed).to be true
      end
    end

    context "updating acquisition info" do
      it "saves acquisition details" do
        patch item_path(item), params: {
          item: {
            acquisition_date: "2024-01-15",
            acquisition_price: "25.50",
            notes: "From GP"
          }
        }
        item.reload
        expect(item.acquisition_date).to eq(Date.new(2024, 1, 15))
        expect(item.acquisition_price).to eq(25.50)
        expect(item.notes).to eq("From GP")
      end
    end

    context "with invalid parameters" do
      it "re-renders edit form" do
        patch item_path(item), params: { item: { language: "invalid" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
```

### System Specs

```ruby
# spec/system/item_detail_spec.rb
require "rails_helper"

RSpec.describe "Item Detail", type: :system do
  before do
    driven_by(:selenium_headless)
  end

  let(:collection) { create(:collection, name: "My Collection") }
  let(:card) { MTGJSON::Card.first }
  let!(:item) do
    create(:item,
      collection: collection,
      card_uuid: card.uuid,
      condition: :near_mint,
      finish: :nonfoil,
      language: "en"
    )
  end

  describe "viewing item details" do
    before { visit item_path(item) }

    it "displays card name" do
      expect(page).to have_content(card.name)
    end

    it "displays card image" do
      expect(page).to have_css("img[alt*='#{card.name}']")
    end

    it "displays condition" do
      expect(page).to have_content("Near Mint")
    end

    it "displays collection name" do
      expect(page).to have_link(collection.name)
    end

    it "shows edit button" do
      expect(page).to have_link("Edit")
    end

    it "shows link to card detail" do
      expect(page).to have_link("View Card")
    end
  end

  describe "editing an item" do
    before { visit edit_item_path(item) }

    it "shows current values" do
      expect(page).to have_select("item[condition]", selected: "Near Mint (NM)")
    end

    it "updates condition" do
      select "Lightly Played (LP)", from: "item[condition]"
      click_button "Save Changes"

      expect(page).to have_content("updated")
      expect(page).to have_content("Lightly Played")
    end

    it "updates finish" do
      select "Traditional Foil", from: "item[finish]"
      click_button "Save Changes"

      expect(item.reload.traditional_foil?).to be true
    end

    it "updates language" do
      select "Japanese", from: "item[language]"
      click_button "Save Changes"

      expect(item.reload.language).to eq("ja")
    end

    it "toggles signed flag" do
      check "item[signed]"
      click_button "Save Changes"

      expect(item.reload.signed).to be true
    end

    it "adds acquisition info" do
      fill_in "item[acquisition_date]", with: "2024-01-15"
      fill_in "item[acquisition_price]", with: "25.50"
      fill_in "item[notes]", with: "Trade at GP"
      click_button "Save Changes"

      item.reload
      expect(item.acquisition_date).to eq(Date.new(2024, 1, 15))
      expect(item.acquisition_price).to eq(25.50)
    end

    context "with storage units" do
      let!(:storage_unit) { create(:storage_unit, collection: collection, name: "Box A") }

      it "assigns to storage unit" do
        visit edit_item_path(item)
        select "Box A", from: "item[storage_unit_id]"
        click_button "Save Changes"

        expect(item.reload.storage_unit).to eq(storage_unit)
      end
    end

    it "shows validation errors" do
      # Trigger validation error (if possible)
      # For example, if we had a custom validation
    end

    it "cancels edit" do
      click_link "Cancel"
      expect(page).to have_current_path(item_path(item))
    end
  end

  describe "navigation" do
    before { visit item_path(item) }

    it "navigates to collection" do
      click_link collection.name
      expect(page).to have_current_path(collection_path(collection))
    end

    it "navigates to card detail" do
      click_link "View Card"
      expect(page).to have_current_path(card_path(card.uuid))
    end

    it "navigates back to items list" do
      click_link "Back to Items"
      expect(page).to have_current_path(collection_items_path(collection))
    end
  end
end
```

---

## UI/UX Specifications

### Item Detail Layout

```
┌─────────────────────────────────────────────────────────────┐
│ Collections / My Collection / Items                         │
├─────────────────────────────────────────────────────────────┤
│ Lightning Bolt                           [ Edit ] [ View Card ]│
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐   Card Information                        │
│  │             │   ─────────────────                        │
│  │   [CARD     │   Name: Lightning Bolt                     │
│  │   IMAGE]    │   Type: Instant                            │
│  │             │   Set: Limited Edition Alpha (LEA)         │
│  │             │   Mana Cost: {R}                           │
│  │             │                                            │
│  └─────────────┘   Item Attributes                         │
│                    ───────────────                          │
│                    Condition: [Near Mint (NM)]              │
│                    Finish: Non-foil                         │
│                    Language: English                        │
│                    Signed: No                               │
│                    Altered: No                              │
│                    Misprint: No                             │
│                                                             │
│                    Storage                                  │
│                    ───────                                  │
│                    Collection: My Collection                │
│                    Storage Unit: Box A                      │
│                                                             │
│                    Acquisition                              │
│                    ───────────                              │
│                    Date: January 15, 2024                   │
│                    Price: $25.50                            │
│                    Notes: From GP Vegas                     │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Added 3 days ago · Updated 1 day ago                        │
├─────────────────────────────────────────────────────────────┤
│ ← Back to Items                            [Delete Item]    │
└─────────────────────────────────────────────────────────────┘
```

### Edit Form Layout

```
┌─────────────────────────────────────────────────────────────┐
│ ← Back to Item                                              │
├─────────────────────────────────────────────────────────────┤
│ Edit Item                                                   │
├─────────────────────────────────────────────────────────────┤
│ ┌───┐                                                       │
│ │IMG│ Lightning Bolt                                        │
│ └───┘ Limited Edition Alpha                                 │
│       Card data cannot be edited                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Storage Unit        [Box A                           ▼]    │
│                                                             │
│ Condition           [Near Mint (NM)                  ▼]    │
│                                                             │
│ Finish              [Non-foil                        ▼]    │
│                                                             │
│ Language            [English                         ▼]    │
│                                                             │
│ Special Attributes                                          │
│ ☐ Signed   ☐ Altered   ☐ Misprint                          │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Acquisition Information                                     │
│                                                             │
│ Date Acquired       [2024-01-15    📅] Price Paid [$25.50 ] │
│                                                             │
│ Notes               [From GP Vegas                        ] │
│                     [                                     ] │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                       [ Cancel ] [ Save ]   │
└─────────────────────────────────────────────────────────────┘
```

---

## Dependencies

- **Phase 2.1**: Add Item (item creation)
- **Phase 2.2**: Item List (navigation context)
- **Phase 1.3**: Card Detail (card helpers, image display)

---

## Definition of Done

- [ ] `ItemsController#show` action implemented
- [ ] `ItemsController#edit` action implemented
- [ ] `ItemsController#update` action implemented
- [ ] Routes configured for show, edit, update
- [ ] Item detail displays card info (name, image, type)
- [ ] Item detail displays all item attributes
- [ ] Item detail displays storage location
- [ ] Item detail displays acquisition info
- [ ] Edit form pre-fills current values
- [ ] Edit form includes all editable fields
- [ ] Storage unit dropdown scoped to collection
- [ ] Validation errors displayed on form
- [ ] Success redirect and flash message
- [ ] Navigation links work (collection, storage unit, card)
- [ ] Timestamps displayed
- [ ] Delete button present (links to Phase 2.5)
- [ ] All request specs pass
- [ ] All system specs pass
- [ ] Responsive design
- [ ] Accessible form (labels, errors)
- [ ] `bin/rubocop --fix` passes
- [ ] `bin/rspec` passes

---

## Future Enhancements (Not in MVP)

- Inline editing (click to edit individual fields)
- Edit history/audit log
- Duplicate item action
- Move to collection action (Phase 2.4)
- Price lookup from MTGJSON
- Image upload for altered/signed cards
- QR code for item
