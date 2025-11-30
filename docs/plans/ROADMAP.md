# Collector MVP Roadmap

## Project Overview

**Application**: Collector - Magic: The Gathering Collection Manager  
**Purpose**: Personal/household inventory tracking for physical MTG card collections  
**License**: GNU AGPL v3.0 (Free Software)  
**Primary Use Case**: "What do I own and where is it?"

### Technology Stack

- **Framework**: Rails 8.1
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Database**: SQLite (multi-database: primary + MTGJSON)
- **Asset Pipeline**: Propshaft + Importmap (no build step)
- **Testing**: RSpec, Capybara, Selenium
- **Card Data**: MTGJSON SQLite database (~500MB, 107K+ cards)

### Development Approach

- Claude Code as primary code writer
- Architectural guidance from experienced Rails developer
- Test-driven development with RSpec
- Incremental feature delivery

---

## Architectural Decisions

### Data Model: Individual Card Tracking

Each physical card is represented as a single `Item` record. The same card (same `card_uuid`) may appear multiple times in a collection when the user owns multiple copies.

**Rationale**: 
- Same card may exist in different storage units or decks
- Cards may have different conditions, finishes, or attributes
- Aggregation ("I own 4 Lightning Bolts") is a reporting concern, not a data model concern
- Supports tracking individual card history (acquisition date, price paid)

### Item Defaults

To enable fast item creation (especially for future bulk operations), most fields have sensible defaults:

| Field | Default | Required |
|-------|---------|----------|
| `card_uuid` | none | **Yes** |
| `collection_id` | none | **Yes** |
| `condition` | `near_mint` | No (defaulted) |
| `finish` | `nonfoil` | No (defaulted) |
| `language` | `en` | No (defaulted) |
| `storage_unit_id` | `nil` | No (loose cards) |
| `signed` | `false` | No |
| `altered` | `false` | No |
| `misprint` | `false` | No |

**Minimum viable item creation**: Select a card and a collection. Everything else is optional or defaulted.

### Storage Model

Storage units support arbitrary nesting (box contains deck boxes, deck box contains deck, etc.). Items without a `storage_unit_id` are considered "loose" within the collection.

### MTGJSON Integration

- Read-only external database (never modified by application)
- Cards referenced by UUID (`card_uuid` foreign key)
- Provides: card details, set information, legalities, rulings, prices, images
- Updated via rake task (`bin/rails mtgjson:refresh`)

### Constraints

- **SQLite only**: No external database services
- **Single-user initially**: No authentication in MVP
- **Offline-capable design**: No external API calls for core functionality
- **Mobile-friendly**: Responsive design, but native apps deferred

---

## Current State

### Working Features

- **Collections**: Full CRUD with name/description
- **Storage Units**: 8 types (box, binder, deck, deck_box, portfolio, toploader_case, loose, other)
- **Nested Storage**: Hierarchical organization with circular reference prevention
- **MTGJSON Database**: Connected and queryable (107K+ cards, 800+ sets)

### Existing But Incomplete

- **Item Model**: Database schema exists, no UI/controller/views
  - Location: `app/models/item.rb`
  - Schema: `db/schema.rb` (items table)
  - Tests: `spec/models/item_spec.rb`

### Not Yet Built

- Card search/browse interface
- Item management UI
- Card display (images, details)
- Price/value reporting

---

## MVP Phases

### Phase 1: Card Discovery

Enable users to find cards in the MTGJSON database before adding them to collections.

#### 1.1 Set Browser

Browse the complete list of MTG sets and view cards within each set.

**User Stories**:
- View all sets, sorted by release date (newest first)
- Filter sets by type (expansion, core, masters, etc.)
- Click a set to view all cards in that set
- See set metadata (release date, card count, set code)

**Technical Notes**:
- Uses `MTGJSON::Set` and `MTGJSON::Card` models
- Pagination required (some sets have 300+ cards)
- Set images available via Scryfall CDN (optional enhancement)

#### 1.2 Card Search

Search for cards by name and set code.

**User Stories**:
- Search cards by name (partial match)
- Search cards by set code (exact match)
- See search results with card name, set, and type
- Click a result to view card details

**Technical Notes**:
- Uses `MTGJSON::Card.by_name` and `MTGJSON::Card.by_set` scopes
- Consider search debouncing for UX
- Results should be paginated

#### 1.3 Card Detail View

Display comprehensive card information from MTGJSON.

**User Stories**:
- View card name, mana cost, type line, rules text
- View power/toughness (creatures), loyalty (planeswalkers)
- View set information and rarity
- View format legalities
- View rulings (if any)
- See card image (via Scryfall CDN)

**Technical Notes**:
- Card images: `https://cards.scryfall.io/normal/front/{a}/{b}/{scryfallId}.jpg`
- Scryfall ID available via `MTGJSON::CardIdentifier`
- Legalities via `MTGJSON::CardLegality`
- Rulings via `MTGJSON::CardRuling`

---

### Phase 2: Item Management (Core MVP)

The essential functionality for tracking owned cards.

#### 2.1 Add Item to Collection

Add a card from MTGJSON to a user's collection.

**User Stories**:
- From card detail view, click "Add to Collection"
- Select target collection (required)
- Optionally select storage unit within collection
- Optionally specify condition, finish, language
- Item created with sensible defaults for unspecified fields

**Technical Notes**:
- Requires Item controller and views
- Form should show card being added (confirmation)
- Redirect to collection or item detail after creation

#### 2.2 Item List View

View all items in a collection.

**User Stories**:
- See all items in a collection as a list/grid
- Each item shows: card name, set, condition, finish, storage location
- Click an item to view full details
- Visual distinction for foils, signed, altered cards

**Technical Notes**:
- Eager load MTGJSON card data to avoid N+1
- Consider card image thumbnails
- Pagination for large collections

#### 2.3 Item Detail & Edit

View and modify item attributes.

**User Stories**:
- View all item attributes (condition, finish, language, etc.)
- View associated card details (from MTGJSON)
- Edit item attributes (condition, finish, storage unit, notes, etc.)
- See acquisition information (date, price) if recorded

**Technical Notes**:
- Edit form for Item attributes
- Card data is read-only (from MTGJSON)
- Storage unit dropdown scoped to same collection

#### 2.4 Item Organization

Move items between storage units and collections.

**User Stories**:
- Change item's storage unit (within same collection)
- Move item to a different collection
- Move item to "loose" (no storage unit)
- Bulk move multiple items (stretch goal)

**Technical Notes**:
- Moving to different collection may require selecting new storage unit
- Consider confirmation for cross-collection moves
- Bulk operations deferred but UI should not preclude them

#### 2.5 Delete Items

Remove items from collection.

**User Stories**:
- Delete a single item with confirmation
- Item is permanently removed (no soft delete in MVP)

**Technical Notes**:
- Standard Rails destroy with Turbo
- Consider showing what's being deleted (card name, set)

---

### Phase 3: Collection Intelligence

Tools for understanding and navigating collections.

#### 3.1 Collection Filtering & Sorting

Filter and sort items within a collection.

**User Stories**:
- Filter items by set
- Filter items by color/color identity
- Filter items by card type (creature, instant, etc.)
- Filter items by condition
- Filter items by finish (foil vs non-foil)
- Sort by name, set, date added, condition

**Technical Notes**:
- Filters can combine (AND logic)
- Consider Turbo Frames for filter updates
- Preserve filter state in URL params

#### 3.2 Storage Unit Contents

View items organized by storage location.

**User Stories**:
- From storage unit view, see all items in that unit
- See items in nested storage units
- Quick navigation between storage units
- See item count per storage unit

**Technical Notes**:
- Builds on existing storage unit views
- May need new partial for item list within storage context

#### 3.3 Collection Statistics

Dashboard showing collection composition.

**User Stories**:
- Total card count
- Breakdown by set (top sets)
- Breakdown by color
- Breakdown by card type
- Breakdown by condition
- Unique cards vs total cards

**Technical Notes**:
- Aggregation queries on Item model
- Group by card_uuid for unique count
- Consider caching for large collections

---

### Phase 4: Value Reporting

Financial tracking and reporting features.

#### 4.1 Price Display

Show current market prices for cards.

**User Stories**:
- See current price on card detail view
- See price on item detail view
- Price displayed in USD (primary market)
- Show price source/date

**Technical Notes**:
- Uses `MTGJSON::CardPrice` model
- MTGJSON includes TCGPlayer, CardMarket prices
- Prices may be stale (updated with MTGJSON refresh)
- Consider showing price range (low/mid/high)

#### 4.2 Collection Valuation

Calculate total collection value.

**User Stories**:
- See total estimated value of collection
- See value breakdown by storage unit
- See most valuable cards
- Understand valuation methodology

**Technical Notes**:
- Sum of individual card prices
- Handle missing prices gracefully
- Consider condition-based price adjustments (stretch)
- Export valuation report (stretch)

---

## Future Features (Not in MVP)

The following features are explicitly deferred. The MVP should not preclude their future implementation.

### Bulk Operations
- Import from CSV/other apps
- Export collection data
- Bulk add multiple copies
- Bulk edit items

### Trade Management
- Track trades with other collectors
- Trade history
- Trade value comparison

### Wishlist
- Track cards you want to acquire
- Price alerts (would require external service)

### Multi-User
- User authentication
- Multiple users with separate collections
- Shared household collections

### Deck Building
- Build/track constructed decks
- Deck legality validation
- Deck statistics

### Mobile Native
- iOS/Android apps
- Barcode scanning for card entry

---

## Technical Guidelines

### Pre-Commit Requirements

Before every commit:
```bash
bin/rubocop --fix  # Linter
bin/rspec          # Full test suite
```

### Testing Strategy

- **Model specs**: Validations, associations, business logic
- **Request specs**: Controller actions, HTTP responses
- **System specs**: Full user workflows with browser

### File Organization

```
app/
├── controllers/
│   ├── collections_controller.rb    # Existing
│   ├── storage_units_controller.rb  # Existing
│   ├── items_controller.rb          # Phase 2
│   ├── sets_controller.rb           # Phase 1 (MTGJSON browsing)
│   └── cards_controller.rb          # Phase 1 (MTGJSON browsing)
├── models/
│   ├── collection.rb                # Existing
│   ├── storage_unit.rb              # Existing
│   ├── item.rb                      # Existing (needs enhancement)
│   └── mtgjson/                     # Existing (read-only)
└── views/
    ├── collections/                 # Existing
    ├── storage_units/               # Existing
    ├── items/                       # Phase 2
    ├── sets/                        # Phase 1
    └── cards/                       # Phase 1
```

### Routes Structure

```ruby
# Existing
resources :collections do
  resources :storage_units, shallow: true
end

# Phase 1: Card Discovery
resources :sets, only: [:index, :show]  # MTGJSON sets
resources :cards, only: [:index, :show] # MTGJSON cards (search)

# Phase 2: Item Management
resources :collections do
  resources :items, shallow: true
end
```

---

## Plan File Structure

Individual feature plans will be created in `docs/plans/` with the naming convention:

```
docs/plans/
├── ROADMAP.md                    # This file
├── phase-1-1-set-browser.md
├── phase-1-2-card-search.md
├── phase-1-3-card-detail.md
├── phase-2-1-add-item.md
├── phase-2-2-item-list.md
├── phase-2-3-item-detail-edit.md
├── phase-2-4-item-organization.md
├── phase-2-5-delete-items.md
├── phase-3-1-filtering-sorting.md
├── phase-3-2-storage-contents.md
├── phase-3-3-statistics.md
├── phase-4-1-price-display.md
└── phase-4-2-collection-valuation.md
```

Each plan file will contain:
- Feature overview and user stories
- Acceptance criteria
- Technical implementation details
- Database changes (if any)
- Test requirements
- Dependencies on other features

---

## Success Criteria

The MVP is complete when a user can:

1. ✅ Create and manage collections (existing)
2. ✅ Create and organize storage units (existing)
3. Browse MTG sets and search for cards
4. View detailed card information
5. Add cards to their collection as items
6. View and edit items in their collection
7. Move items between storage units and collections
8. See the total value of their collection

---

## Revision History

| Date | Change |
|------|--------|
| 2024-11-29 | Initial roadmap created |
