# Phase 2.1: Add Item to Collection

## Feature Overview

Enable users to add cards from the MTGJSON database to their personal collections. This is the core functionality that transforms Collector from a card browser into a collection management tool.

**Priority**: Critical (core MVP functionality)
**Dependencies**: Phase 1.3 (Card Detail View)
**Estimated Complexity**: Medium

---

## User Stories

### US-2.1.1: Add Card from Detail View
**As a** collector
**I want to** add a card to my collection from its detail page
**So that** I can track cards I own

### US-2.1.2: Select Target Collection
**As a** collector
**I want to** choose which collection to add a card to
**So that** I can organize my cards across multiple collections

### US-2.1.3: Specify Storage Location
**As a** collector
**I want to** optionally specify where the card is stored
**So that** I can track its physical location

### US-2.1.4: Set Card Attributes
**As a** collector
**I want to** specify condition, finish, and language
**So that** I can accurately represent my copy of the card

### US-2.1.5: Use Sensible Defaults
**As a** collector
**I want to** quickly add cards with minimal input
**So that** I can efficiently catalog my collection

### US-2.1.6: Confirm Addition
**As a** collector
**I want to** see confirmation that my card was added
**So that** I know the action was successful

---

## Acceptance Criteria

### AC-2.1.1: Add to Collection Button

```gherkin
Feature: Add to Collection Button

  Scenario: Button visible on card detail page
    Given I am viewing a card detail page
    Then I should see an "Add to Collection" button

  Scenario: Button requires at least one collection
    Given I have no collections
    When I view a card detail page
    Then the "Add to Collection" button should be disabled
    And I should see "Create a collection first"

  Scenario: Click opens add item form
    Given I have at least one collection
    When I click "Add to Collection"
    Then I should see the add item form
    And the card name and image should be displayed
```

### AC-2.1.2: Add Item Form

```gherkin
Feature: Add Item Form

  Scenario: Form displays card information
    Given I am adding "Lightning Bolt" to my collection
    Then I should see the card name "Lightning Bolt"
    And I should see the card image
    And I should see the set name

  Scenario: Form has required fields
    When I view the add item form
    Then I should see a collection dropdown (required)
    And it should list all my collections

  Scenario: Form has optional fields
    When I view the add item form
    Then I should see:
      | field         | type     | default        |
      | storage_unit  | dropdown | (none)         |
      | condition     | dropdown | Near Mint      |
      | finish        | dropdown | Non-foil       |
      | language      | dropdown | English (en)   |
      | signed        | checkbox | unchecked      |
      | altered       | checkbox | unchecked      |
      | misprint      | checkbox | unchecked      |

  Scenario: Storage unit dropdown filtered by collection
    Given I have collections "Main" and "Trade Binder"
    And "Main" has storage units "Box A" and "Box B"
    When I select collection "Main"
    Then the storage unit dropdown should show "Box A" and "Box B"
    When I select collection "Trade Binder"
    Then the storage unit dropdown should update to show Trade Binder's units
```

### AC-2.1.3: Item Creation with Defaults

```gherkin
Feature: Item Creation with Defaults

  Scenario: Create item with minimum input
    Given I am adding a card to my collection
    When I select a collection
    And I click "Add to Collection"
    Then an item should be created with:
      | field        | value      |
      | card_uuid    | (from card)|
      | collection   | (selected) |
      | condition    | near_mint  |
      | finish       | nonfoil    |
      | language     | en         |
      | signed       | false      |
      | altered      | false      |
      | misprint     | false      |
    And the storage_unit should be nil (loose)

  Scenario: Create item with all fields
    Given I am adding a card to my collection
    When I fill in all optional fields
    And I click "Add to Collection"
    Then the item should be created with all specified values
```

### AC-2.1.4: Condition Options

```gherkin
Feature: Condition Selection

  Scenario: All conditions available
    When I view the condition dropdown
    Then I should see options:
      | value            | display            |
      | near_mint        | Near Mint (NM)     |
      | lightly_played   | Lightly Played (LP)|
      | moderately_played| Moderately Played (MP)|
      | heavily_played   | Heavily Played (HP)|
      | damaged          | Damaged (D)        |
```

### AC-2.1.5: Finish Options

```gherkin
Feature: Finish Selection

  Scenario: All finishes available
    When I view the finish dropdown
    Then I should see options:
      | value            | display           |
      | nonfoil          | Non-foil          |
      | traditional_foil | Traditional Foil  |
      | etched           | Etched Foil       |
      | glossy           | Glossy            |
      | textured         | Textured Foil     |
      | surge_foil       | Surge Foil        |
```

### AC-2.1.6: Language Selection

```gherkin
Feature: Language Selection

  Scenario: Common languages available
    When I view the language dropdown
    Then I should see options including:
      | code | display    |
      | en   | English    |
      | ja   | Japanese   |
      | de   | German     |
      | fr   | French     |
      | it   | Italian    |
      | es   | Spanish    |
      | pt   | Portuguese |
      | ko   | Korean     |
      | ru   | Russian    |
      | zhs  | Chinese (Simplified) |
      | zht  | Chinese (Traditional)|
```

### AC-2.1.7: Success Flow

```gherkin
Feature: Successful Item Creation

  Scenario: Item created successfully
    Given I am adding a card to my collection "Main Collection"
    When I submit the form with valid data
    Then I should see a success message "Card added to Main Collection"
    And I should be redirected to the collection items page
    Or I should be redirected to the card detail page with confirmation

  Scenario: Add another copy
    Given I just added a card to my collection
    When I click "Add Another Copy"
    Then I should see the add item form for the same card
    And previous values should be preserved (except storage unit)
```

### AC-2.1.8: Validation Errors

```gherkin
Feature: Form Validation

  Scenario: Collection required
    Given I am on the add item form
    When I submit without selecting a collection
    Then I should see an error "Collection is required"

  Scenario: Invalid language code
    Given I manually enter an invalid language code
    When I submit the form
    Then I should see an error "Language must be 2 characters"
```

### AC-2.1.9: Acquisition Information (Optional)

```gherkin
Feature: Acquisition Information

  Scenario: Record acquisition details
    When I view the add item form
    Then I should see optional fields:
      | field            | type    |
      | acquisition_date | date    |
      | acquisition_price| decimal |
      | notes            | textarea|

  Scenario: Price validation
    Given I enter acquisition price "-5.00"
    When I submit the form
    Then I should see an error for invalid price
```

---

## Technical Implementation

### Routes

```ruby
# config/routes.rb
# Simplified: Items nested under collections with shallow routing
# Card UUID passed as query parameter when coming from card detail page
resources :collections do
  resources :items, shallow: true
  resources :storage_units, shallow: true
end
```

**Routes generated for this feature:**
- `GET /collections/:collection_id/items/new?card_uuid=xxx` → `items#new` (add item form)
- `POST /collections/:collection_id/items` → `items#create` (create item)

**Flow from card detail page:**
1. User clicks "Add to Collection" on card detail page
2. User selects a collection (dropdown/modal on card page)
3. Redirects to `/collections/:id/items/new?card_uuid=xxx`

### Controller

```ruby
# app/controllers/items_controller.rb
class ItemsController < ApplicationController
  before_action :set_collection, only: [:index, :new, :create]
  before_action :set_item, only: [:show, :edit, :update, :destroy]
  before_action :set_card, only: [:new, :create]

  def new
    @item = Item.new(
      card_uuid: @card.uuid,
      condition: :near_mint,
      finish: :nonfoil,
      language: "en"
    )
    @storage_units = @collection.storage_units.order(:name)
  end

  def create
    @item = @collection.items.build(item_params)
    @item.card_uuid = @card.uuid

    if @item.save
      redirect_to collection_items_path(@collection),
                  notice: "#{@card.name} added to #{@collection.name}"
    else
      @storage_units = @collection.storage_units.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_collection
    @collection = Collection.find(params[:collection_id])
  end

  def set_card
    @card = MTGJSON::Card.includes(:set, :identifiers)
                         .find_by!(uuid: params[:card_uuid])
  rescue ActiveRecord::RecordNotFound
    redirect_to cards_path, alert: "Card not found"
  end

  def set_item
    @item = Item.find(params[:id])
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
      :notes
    )
  end
end
```

### Storage Unit Dynamic Loading (Stimulus)

```javascript
// app/javascript/controllers/collection_storage_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["collection", "storageUnit"]
  static values = { url: String }

  connect() {
    this.updateStorageUnits()
  }

  updateStorageUnits() {
    const collectionId = this.collectionTarget.value
    if (!collectionId) {
      this.storageUnitTarget.innerHTML = '<option value="">No storage unit (loose)</option>'
      return
    }

    fetch(`/collections/${collectionId}/storage_units.json`)
      .then(response => response.json())
      .then(units => {
        let options = '<option value="">No storage unit (loose)</option>'
        units.forEach(unit => {
          options += `<option value="${unit.id}">${unit.name}</option>`
        })
        this.storageUnitTarget.innerHTML = options
      })
  }
}
```

### Views

```
app/views/items/
├── new.html.erb          # Add item form
├── _form.html.erb        # Form partial (reused in edit)
├── _card_preview.html.erb # Card preview for form
└── _item.html.erb        # Item partial (for lists)
```

### Form View

```erb
<%# app/views/items/new.html.erb %>
<% content_for :title, "Add #{@card.name} to Collection" %>

<div class="max-w-2xl mx-auto">
  <nav class="mb-6">
    <%= link_to "← Back to Card", card_path(@card.uuid),
        class: "text-indigo-600 hover:text-indigo-800" %>
  </nav>

  <h1 class="text-2xl font-bold mb-6">Add to Collection</h1>

  <div class="bg-white rounded-lg shadow-sm border p-6">
    <!-- Card Preview -->
    <%= render "card_preview", card: @card %>

    <!-- Add Item Form -->
    <%= render "form", item: @item, card: @card, collections: @collections %>
  </div>
</div>
```

### Language Helper

```ruby
# app/helpers/items_helper.rb
module ItemsHelper
  LANGUAGES = [
    ["English", "en"],
    ["Japanese", "ja"],
    ["German", "de"],
    ["French", "fr"],
    ["Italian", "it"],
    ["Spanish", "es"],
    ["Portuguese", "pt"],
    ["Korean", "ko"],
    ["Russian", "ru"],
    ["Chinese (Simplified)", "zhs"],
    ["Chinese (Traditional)", "zht"],
    ["Phyrexian", "ph"],
    ["Arabic", "ar"],
    ["Hebrew", "he"],
    ["Latin", "la"],
    ["Ancient Greek", "grc"],
    ["Sanskrit", "sa"]
  ].freeze

  def language_options
    LANGUAGES
  end

  def language_name(code)
    LANGUAGES.find { |_, c| c == code }&.first || code.upcase
  end

  def condition_options
    Item.conditions.keys.map do |c|
      [condition_display_name(c), c]
    end
  end

  def condition_display_name(condition)
    abbreviations = {
      "near_mint" => "NM",
      "lightly_played" => "LP",
      "moderately_played" => "MP",
      "heavily_played" => "HP",
      "damaged" => "D"
    }
    "#{condition.humanize} (#{abbreviations[condition]})"
  end

  def finish_options
    Item.finishes.keys.map do |f|
      [f.humanize.titleize, f]
    end
  end
end
```

---

## Database Changes

**None required.** The `items` table already exists with all necessary columns.

---

## Test Requirements

### Model Specs

```ruby
# spec/models/item_spec.rb (additions)
require "rails_helper"

RSpec.describe Item, type: :model do
  describe "validations" do
    it { should validate_presence_of(:card_uuid) }
    it { should validate_presence_of(:collection_id) }
    it { should validate_presence_of(:condition) }
    it { should validate_presence_of(:finish) }
    it { should validate_presence_of(:language) }
    it { should validate_length_of(:language).is_equal_to(2) }
  end

  describe "associations" do
    it { should belong_to(:collection) }
    it { should belong_to(:storage_unit).optional }
  end

  describe "enums" do
    it { should define_enum_for(:condition).with_values(
      near_mint: 0, lightly_played: 1, moderately_played: 2,
      heavily_played: 3, damaged: 4
    )}

    it { should define_enum_for(:finish).with_values(
      nonfoil: 0, traditional_foil: 1, etched: 2,
      glossy: 3, textured: 4, surge_foil: 5
    )}
  end

  describe "#card" do
    let(:item) { build(:item, card_uuid: card.uuid) }
    let(:card) { MTGJSON::Card.first }

    it "returns the associated MTGJSON card" do
      expect(item.card).to eq(card)
    end

    it "memoizes the result" do
      expect(MTGJSON::Card).to receive(:find_by).once.and_return(card)
      2.times { item.card }
    end
  end

  describe "defaults" do
    let(:collection) { create(:collection) }
    let(:card) { MTGJSON::Card.first }

    it "creates with minimum required fields" do
      item = Item.create!(
        collection: collection,
        card_uuid: card.uuid,
        condition: :near_mint,
        finish: :nonfoil,
        language: "en"
      )
      expect(item).to be_persisted
    end
  end
end
```

### Request Specs

```ruby
# spec/requests/items_spec.rb
require "rails_helper"

RSpec.describe "Items", type: :request do
  let(:card) { MTGJSON::Card.first }
  let(:collection) { create(:collection) }

  describe "GET /cards/:card_uuid/items/new" do
    context "when collections exist" do
      before { collection }

      it "returns successful response" do
        get new_card_item_path(card.uuid)
        expect(response).to have_http_status(:ok)
      end

      it "displays the card name" do
        get new_card_item_path(card.uuid)
        expect(response.body).to include(card.name)
      end

      it "displays collection dropdown" do
        get new_card_item_path(card.uuid)
        expect(response.body).to include(collection.name)
      end
    end

    context "when no collections exist" do
      it "shows prompt to create collection" do
        get new_card_item_path(card.uuid)
        expect(response.body).to include("Create a collection")
      end
    end

    context "when card does not exist" do
      it "redirects with error" do
        get new_card_item_path("invalid-uuid")
        expect(response).to redirect_to(cards_path)
      end
    end
  end

  describe "POST /cards/:card_uuid/items" do
    let(:valid_params) do
      {
        item: {
          collection_id: collection.id,
          condition: "near_mint",
          finish: "nonfoil",
          language: "en"
        }
      }
    end

    context "with valid parameters" do
      it "creates a new item" do
        expect {
          post card_items_path(card.uuid), params: valid_params
        }.to change(Item, :count).by(1)
      end

      it "redirects to collection items" do
        post card_items_path(card.uuid), params: valid_params
        expect(response).to redirect_to(collection_items_path(collection))
      end

      it "shows success message" do
        post card_items_path(card.uuid), params: valid_params
        follow_redirect!
        expect(response.body).to include("added to")
      end

      it "sets the card_uuid from the URL" do
        post card_items_path(card.uuid), params: valid_params
        expect(Item.last.card_uuid).to eq(card.uuid)
      end
    end

    context "with storage unit" do
      let(:storage_unit) { create(:storage_unit, collection: collection) }

      it "assigns item to storage unit" do
        params = valid_params.deep_merge(item: { storage_unit_id: storage_unit.id })
        post card_items_path(card.uuid), params: params
        expect(Item.last.storage_unit).to eq(storage_unit)
      end
    end

    context "with invalid parameters" do
      it "does not create item without collection" do
        params = valid_params.deep_merge(item: { collection_id: nil })
        expect {
          post card_items_path(card.uuid), params: params
        }.not_to change(Item, :count)
      end

      it "re-renders form with errors" do
        params = valid_params.deep_merge(item: { collection_id: nil })
        post card_items_path(card.uuid), params: params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with all optional fields" do
      let(:storage_unit) { create(:storage_unit, collection: collection) }

      it "saves all attributes" do
        params = {
          item: {
            collection_id: collection.id,
            storage_unit_id: storage_unit.id,
            condition: "lightly_played",
            finish: "traditional_foil",
            language: "ja",
            signed: true,
            altered: false,
            misprint: true,
            acquisition_date: "2024-01-15",
            acquisition_price: "25.50",
            notes: "From GP Vegas"
          }
        }

        post card_items_path(card.uuid), params: params

        item = Item.last
        expect(item.condition).to eq("lightly_played")
        expect(item.finish).to eq("traditional_foil")
        expect(item.language).to eq("ja")
        expect(item.signed).to be true
        expect(item.misprint).to be true
        expect(item.acquisition_date).to eq(Date.new(2024, 1, 15))
        expect(item.acquisition_price).to eq(25.50)
        expect(item.notes).to eq("From GP Vegas")
      end
    end
  end
end
```

### System Specs

```ruby
# spec/system/add_item_spec.rb
require "rails_helper"

RSpec.describe "Add Item to Collection", type: :system do
  before do
    driven_by(:selenium_headless)
  end

  let!(:collection) { create(:collection, name: "My Collection") }
  let(:card) { MTGJSON::Card.first }

  describe "adding a card from detail page" do
    it "shows add to collection button" do
      visit card_path(card.uuid)
      expect(page).to have_link("Add to Collection")
    end

    it "navigates to add item form" do
      visit card_path(card.uuid)
      click_link "Add to Collection"

      expect(page).to have_content("Add to Collection")
      expect(page).to have_content(card.name)
    end
  end

  describe "add item form" do
    before { visit new_card_item_path(card.uuid) }

    it "displays card preview" do
      expect(page).to have_content(card.name)
    end

    it "shows collection dropdown" do
      expect(page).to have_select("item[collection_id]")
      expect(page).to have_content("My Collection")
    end

    it "shows condition dropdown with default" do
      expect(page).to have_select("item[condition]", selected: "Near Mint (NM)")
    end

    it "shows finish dropdown with default" do
      expect(page).to have_select("item[finish]", selected: "Nonfoil")
    end

    it "shows language dropdown with default" do
      expect(page).to have_select("item[language]", selected: "English")
    end
  end

  describe "creating an item" do
    before { visit new_card_item_path(card.uuid) }

    it "creates item with defaults" do
      select "My Collection", from: "item[collection_id]"
      click_button "Add to Collection"

      expect(page).to have_content("added to My Collection")
      expect(Item.count).to eq(1)
    end

    it "creates item with custom attributes" do
      select "My Collection", from: "item[collection_id]"
      select "Lightly Played (LP)", from: "item[condition]"
      select "Traditional Foil", from: "item[finish]"
      select "Japanese", from: "item[language]"
      check "item[signed]"

      click_button "Add to Collection"

      item = Item.last
      expect(item.lightly_played?).to be true
      expect(item.traditional_foil?).to be true
      expect(item.language).to eq("ja")
      expect(item.signed).to be true
    end

    context "with storage unit" do
      let!(:storage_unit) { create(:storage_unit, collection: collection, name: "Box A") }

      it "allows selecting storage unit" do
        select "My Collection", from: "item[collection_id]"

        # Wait for storage units to load via Stimulus
        expect(page).to have_select("item[storage_unit_id]", with_options: ["Box A"])

        select "Box A", from: "item[storage_unit_id]"
        click_button "Add to Collection"

        expect(Item.last.storage_unit).to eq(storage_unit)
      end
    end

    context "with validation errors" do
      it "shows errors when collection not selected" do
        click_button "Add to Collection"

        expect(page).to have_content("Collection")
        expect(page).to have_css("[data-testid='error-message']")
      end
    end
  end

  describe "no collections available" do
    before { Collection.destroy_all }

    it "shows message to create collection" do
      visit new_card_item_path(card.uuid)

      expect(page).to have_content("Create a collection first")
      expect(page).to have_link(href: new_collection_path)
    end
  end
end
```

### Helper Specs

```ruby
# spec/helpers/items_helper_spec.rb
require "rails_helper"

RSpec.describe ItemsHelper, type: :helper do
  describe "#language_options" do
    it "returns array of language options" do
      expect(helper.language_options).to include(["English", "en"])
      expect(helper.language_options).to include(["Japanese", "ja"])
    end
  end

  describe "#language_name" do
    it "returns language name for code" do
      expect(helper.language_name("en")).to eq("English")
      expect(helper.language_name("ja")).to eq("Japanese")
    end

    it "returns uppercase code for unknown language" do
      expect(helper.language_name("xx")).to eq("XX")
    end
  end

  describe "#condition_display_name" do
    it "includes abbreviation" do
      expect(helper.condition_display_name("near_mint")).to eq("Near mint (NM)")
      expect(helper.condition_display_name("lightly_played")).to eq("Lightly played (LP)")
    end
  end

  describe "#finish_options" do
    it "returns all finish options" do
      options = helper.finish_options
      expect(options).to include(["Nonfoil", "nonfoil"])
      expect(options).to include(["Traditional Foil", "traditional_foil"])
    end
  end
end
```

---

## UI/UX Specifications

### Add Item Form Layout

```
┌─────────────────────────────────────────────────────────────┐
│ ← Back to Card                                              │
├─────────────────────────────────────────────────────────────┤
│ Add to Collection                                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐   Lightning Bolt                          │
│  │             │   Instant                                  │
│  │   [CARD     │   Limited Edition Alpha (LEA)              │
│  │   IMAGE]    │                                            │
│  │             │                                            │
│  └─────────────┘                                            │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Collection *        [Select collection         ▼]          │
│                                                             │
│ Storage Unit        [No storage unit (loose)   ▼]          │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Card Condition                                              │
│                                                             │
│ Condition           [Near Mint (NM)            ▼]          │
│                                                             │
│ Finish              [Non-foil                  ▼]          │
│                                                             │
│ Language            [English                   ▼]          │
│                                                             │
│ □ Signed   □ Altered   □ Misprint                          │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Acquisition Details (optional)                              │
│                                                             │
│ Date Acquired       [                          📅]          │
│                                                             │
│ Price Paid          [$                           ]          │
│                                                             │
│ Notes               [                            ]          │
│                     [                            ]          │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                     [  Add to Collection  ]                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Card Detail Page with Button

```
┌─────────────────────────────────────────────────────────────┐
│ ...card detail content...                                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [  Add to Collection  ]    [  View Other Printings  ]      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Success Message

```
┌─────────────────────────────────────────────────────────────┐
│ ✓ Lightning Bolt added to My Collection                     │
│                                                             │
│   [View in Collection]  [Add Another Copy]                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Dependencies

- **Phase 1.3**: Card Detail View (button placement)
- **Collection model**: For collection dropdown
- **StorageUnit model**: For storage unit dropdown
- **Item model**: Already exists with validations

---

## Definition of Done

- [ ] `ItemsController` with `new` and `create` actions
- [ ] Routes configured for `/cards/:card_uuid/items/new` and `create`
- [ ] "Add to Collection" button on card detail page
- [ ] Add item form displays card preview
- [ ] Collection dropdown (required)
- [ ] Storage unit dropdown (dynamic, filtered by collection)
- [ ] Condition dropdown with all options
- [ ] Finish dropdown with all options
- [ ] Language dropdown with common languages
- [ ] Signed/Altered/Misprint checkboxes
- [ ] Optional acquisition fields (date, price, notes)
- [ ] Defaults applied (near_mint, nonfoil, en)
- [ ] Success redirect to collection items page
- [ ] Success flash message with card name
- [ ] Validation errors displayed
- [ ] Stimulus controller for dynamic storage unit loading
- [ ] All model specs pass
- [ ] All request specs pass
- [ ] All system specs pass
- [ ] All helper specs pass
- [ ] Responsive design works on mobile
- [ ] Accessible form (labels, errors, keyboard)
- [ ] `bin/rubocop --fix` passes
- [ ] `bin/rspec` passes

---

## Future Enhancements (Not in MVP)

- Quick add (single click, all defaults)
- Add multiple copies at once
- Copy from existing item
- Barcode/camera scanning
- Recent collections shortcut
- Grading information (service, score, cert number)
- Price lookup suggestions
