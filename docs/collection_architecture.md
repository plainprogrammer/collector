# Collection Management Architecture

This document describes the architectural decisions and structure of the collection management system as implemented through MVP Phases 1 and 2.

## Overview

Collector is a Rails 8.1 application for managing Magic: The Gathering card collections. The system enables users to track physical card ownership with detailed metadata about condition, location, and acquisition history.

**Core Question**: "What cards do I own and where are they?"

## Data Model

### Entity Relationships

```
Collection (1) ──────────────────────────< (N) Item
     │                                         │
     │                                         │
     └──────< (N) StorageUnit >────────────────┘
                    │                    (optional)
                    │
                    └──< (N) StorageUnit (nested children)


Item.card_uuid ─────────────────────────> MTGJSON::Card (read-only, separate DB)
```

### Collections

Collections are the top-level organizational unit. Each collection represents a logical grouping of cards, such as:
- Main collection
- Trade binder
- Decks for specific formats
- Cards for sale

**Model**: `app/models/collection.rb`

```ruby
class Collection < ApplicationRecord
  has_many :storage_units, dependent: :destroy
  has_many :items, dependent: :destroy
  validates :name, presence: true
end
```

**Key Decisions**:
- Collections are standalone entities (no nesting)
- Deleting a collection cascades to all storage units and items
- Name is the only required field; description is optional

### Storage Units

Storage units represent physical containers for organizing cards within a collection. They support arbitrary nesting to model real-world storage hierarchies.

**Model**: `app/models/storage_unit.rb`

**Supported Types** (enum):
| Type | Value | Description |
|------|-------|-------------|
| `box` | 0 | Generic storage box |
| `binder` | 1 | Card binder |
| `deck` | 2 | Constructed deck |
| `deck_box` | 3 | Container for decks |
| `portfolio` | 4 | Display portfolio |
| `toploader_case` | 5 | Toploader storage |
| `loose` | 6 | Loose cards area |
| `other` | 99 | Other container types |

**Nesting Architecture**:
- Storage units can contain other storage units via `parent_id`
- Example: Box → Deck Box → Deck
- Circular reference prevention via `prevent_circular_nesting` validation
- No depth limit enforced (real-world hierarchies are typically shallow)

**Key Decisions**:
- Storage units belong to exactly one collection
- When a storage unit is deleted, child units are destroyed (`dependent: :destroy`)
- When a storage unit is deleted, items become "loose" (`dependent: :nullify`)
- Location field available for physical placement descriptions (e.g., "Shelf 3")

### Items

Items represent individual physical cards in a collection. Each card copy is a separate record, even if you own multiple copies of the same card.

**Model**: `app/models/item.rb`

**Schema**:
```ruby
create_table "items" do |t|
  t.integer  "collection_id", null: false
  t.integer  "storage_unit_id"              # optional - nil means "loose"
  t.string   "card_uuid", null: false       # references MTGJSON::Card
  t.integer  "condition", null: false       # enum
  t.integer  "finish", null: false          # enum
  t.string   "language", limit: 2, default: "en", null: false
  t.boolean  "signed", default: false
  t.boolean  "altered", default: false
  t.boolean  "misprint", default: false
  t.string   "grading_service"
  t.decimal  "grading_score", precision: 3, scale: 1
  t.date     "acquisition_date"
  t.decimal  "acquisition_price", precision: 10, scale: 2
  t.text     "notes"
  t.timestamps
end
```

**Condition Enum**:
| Condition | Value | Abbreviation |
|-----------|-------|--------------|
| `near_mint` | 0 | NM |
| `lightly_played` | 1 | LP |
| `moderately_played` | 2 | MP |
| `heavily_played` | 3 | HP |
| `damaged` | 4 | D |

**Finish Enum**:
| Finish | Value |
|--------|-------|
| `nonfoil` | 0 |
| `traditional_foil` | 1 |
| `etched` | 2 |
| `glossy` | 3 |
| `textured` | 4 |
| `surge_foil` | 5 |

**Key Decisions**:

1. **Individual Card Tracking**: Each physical card is a separate `Item` record. The same card (same `card_uuid`) may appear multiple times when the user owns multiple copies. This supports:
   - Different conditions for each copy
   - Different storage locations
   - Individual acquisition history
   - Future features like trade tracking

2. **Sensible Defaults**: To enable fast item creation:
   - `condition` defaults to `near_mint`
   - `finish` defaults to `nonfoil`
   - `language` defaults to `"en"` (English)
   - Storage unit defaults to `nil` (loose cards)

3. **Loose Cards**: Items with `storage_unit_id = nil` are considered "loose" within the collection—not in any specific container.

4. **Cross-Database Reference**: Items reference MTGJSON cards via `card_uuid` string, not a foreign key constraint (separate databases).

5. **Storage Unit Validation**: Custom validation ensures `storage_unit` belongs to the same collection as the item:
   ```ruby
   validate :storage_unit_belongs_to_collection
   ```

## Multi-Database Architecture

The application uses Rails 8.1's multi-database support with two separate SQLite databases:

### Primary Database
- **Purpose**: Application data (collections, storage units, items)
- **Access**: Read/write
- **Migrations**: `db/migrate/`
- **File**: `storage/development.sqlite3` (dev), `storage/test.sqlite3` (test)

### MTGJSON Database
- **Purpose**: Card reference data (107K+ cards, 800+ sets)
- **Access**: Read-only (enforced at model level)
- **Migrations**: None (external schema)
- **File**: `storage/mtgjson.sqlite3` (dev), `storage/test_mtgjson.sqlite3` (test)

**Cross-Database Pattern**:
```ruby
class Item < ApplicationRecord
  def card
    @card ||= MTGJSON::Card.find_by(uuid: card_uuid)
  end
end
```

No foreign key constraints exist between databases—referential integrity is maintained at the application level.

## Routing Structure

```ruby
Rails.application.routes.draw do
  # Collections and nested resources
  resources :collections do
    resources :items, shallow: true do
      member do
        get :move
        patch :relocate
      end
    end
    resources :storage_units, shallow: true
  end

  # MTGJSON browsing (Card Discovery)
  resources :sets, only: [:index, :show], param: :code
  resources :cards, only: [:index, :show], param: :uuid

  root "collections#index"
end
```

**Shallow Nesting**: Items and storage units use shallow routing:
- Collection-scoped: `GET /collections/:collection_id/items` (index)
- Collection-scoped: `POST /collections/:collection_id/items` (create)
- Standalone: `GET /items/:id` (show, edit, update, destroy)

This keeps URLs clean while maintaining the collection context where needed.

## Controller Architecture

### ItemsController

The items controller handles full CRUD operations plus item relocation:

```ruby
class ItemsController < ApplicationController
  include Pagy::Method

  before_action :set_collection, only: [:index, :new, :create]
  before_action :set_item, only: [:show, :edit, :update, :destroy, :move, :relocate]
  before_action :set_card, only: [:new, :create]

  # Actions: index, show, new, create, edit, update, destroy, move, relocate
end
```

**Key Patterns**:

1. **Batch Card Loading**: The index action loads MTGJSON cards in a single query to avoid N+1:
   ```ruby
   def load_cards_for_items(items)
     uuids = items.map(&:card_uuid).uniq
     MTGJSON::Card.includes(:set, :identifiers)
                  .where(uuid: uuids)
                  .index_by(&:uuid)
   end
   ```

2. **Card UUID from Query Param**: When creating items, the `card_uuid` comes from a query parameter (from the card detail page), not the form:
   ```ruby
   def set_card
     @card = MTGJSON::Card.find_by!(uuid: params[:card_uuid])
   end
   ```

3. **Separate Relocate Action**: Moving items has its own `move` (form) and `relocate` (process) actions to handle the complexity of cross-collection moves with storage unit changes.

## Item Organization

### Moving Within Same Collection

Changing only the `storage_unit_id` while keeping the same collection:
- Select new storage unit from dropdown
- Or select "No storage unit (loose)"
- Validation ensures storage unit belongs to collection

### Moving Between Collections

When moving to a different collection:
1. Storage unit is automatically cleared (storage units are collection-scoped)
2. User may optionally select a storage unit from the destination collection
3. Warning displayed via Stimulus controller when collection changes

**Implementation**:
```ruby
def move_to_collection!(new_collection, new_storage_unit: nil)
  transaction do
    self.collection = new_collection
    self.storage_unit = new_storage_unit
    save!
  end
end
```

## UI Components

### View Structure

```
app/views/
├── collections/         # Collection CRUD
├── storage_units/       # Storage unit CRUD
├── items/
│   ├── index.html.erb   # Collection items list
│   ├── show.html.erb    # Item detail
│   ├── new.html.erb     # Add item form
│   ├── edit.html.erb    # Edit item form
│   ├── move.html.erb    # Move item form
│   ├── _form.html.erb   # Shared form partial
│   └── _card_preview.html.erb
├── sets/                # Set browser
├── cards/               # Card search/detail
└── shared/
    └── _flash.html.erb
```

### Helpers

**ItemsHelper** (`app/helpers/items_helper.rb`):
- `language_options` / `language_name(code)` - Language display
- `condition_options` / `condition_display_name(condition)` - Condition with abbreviation
- `finish_options` / `finish_badge_class(finish)` - Finish display and styling
- `foil?(item)` - Check if item has foil finish
- `special_attributes(item)` - List of special attributes (signed, altered, misprint)

**CardsHelper** (`app/helpers/cards_helper.rb`):
- `card_image_tag(card, size:, class:)` - Generate Scryfall image tag
- `format_mana_cost(mana_cost)` - Format mana symbols

### Stimulus Controllers

**move-item** (`app/javascript/controllers/move_item_controller.js`):
- Handles dynamic storage unit dropdown updates when collection changes
- Shows warning when moving between collections
- Fetches storage units via JSON endpoint

## Testing Strategy

### Test Types

1. **Model Specs**: Validations, associations, business logic
2. **Request Specs**: Controller actions, HTTP responses, redirects
3. **System Specs**: Full user workflows with Selenium/headless Chrome
4. **Helper Specs**: View helper methods

### Test Coverage Summary (396 examples)

- Item model: validations, enums, associations, cross-database lookup, move logic
- Item requests: CRUD operations, validation errors, flash messages
- Item system: add/edit/move/delete workflows, Turbo confirmations

### Factory Pattern

```ruby
# spec/factories/items.rb
FactoryBot.define do
  factory :item do
    collection
    card_uuid { MTGJSON::Card.first&.uuid || "test-uuid" }
    condition { :near_mint }
    finish { :nonfoil }
    language { "en" }
  end
end
```

## Design Principles

### 1. Individual Card Tracking
Each physical card is a separate record. Aggregation ("I own 4 Lightning Bolts") is a reporting concern, not a data model concern.

### 2. Fast Item Creation
Minimum viable input: select a card and a collection. Everything else uses sensible defaults.

### 3. Offline-Capable
Core functionality doesn't require external API calls. MTGJSON data is local.

### 4. Read-Only Reference Data
MTGJSON models enforce read-only access. Card data is never modified by the application.

### 5. Shallow Routing
Resources use shallow nesting to keep URLs clean while maintaining context where needed.

### 6. Cross-Database Safety
No foreign key constraints between databases. Storage unit validation happens at the application level.

## Future Considerations

The current architecture supports future features:

- **Bulk Operations**: Item records are independent; batch updates are straightforward
- **Filtering/Sorting**: Item attributes are indexed for efficient querying
- **Price Tracking**: MTGJSON includes price data via `CardPrice` model
- **Multi-User**: Collection model is ready for user association
- **Trade Management**: Item history and ownership transfer can be added

## Files Reference

### Models
- `app/models/collection.rb`
- `app/models/storage_unit.rb`
- `app/models/item.rb`
- `app/models/mtgjson/*.rb` (read-only reference data)

### Controllers
- `app/controllers/collections_controller.rb`
- `app/controllers/storage_units_controller.rb`
- `app/controllers/items_controller.rb`
- `app/controllers/sets_controller.rb`
- `app/controllers/cards_controller.rb`

### Views
- `app/views/collections/`
- `app/views/storage_units/`
- `app/views/items/`
- `app/views/sets/`
- `app/views/cards/`

### Database
- `db/schema.rb` (primary database schema)
- `db/migrate/` (migrations)

### Configuration
- `config/routes.rb`
- `config/database.yml` (multi-database configuration)

---

*Document created after completion of MVP Phases 1 (Card Discovery) and 2 (Collection Item Management). Last updated: December 2025.*
