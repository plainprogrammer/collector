# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Collector is a Rails 8.1 application for managing Magic: The Gathering card collections. It integrates with the MTGJSON SQLite database to provide comprehensive card data as a read-only reference source.

**Ruby Version**: 3.4
**Rails Version**: 8.1
**License**: GNU AGPL v3.0

## Commands

### Pre-Commit Requirements

**REQUIRED before every commit:**

```bash
# Run all CI checks locally (linting, security scans, tests)
bin/ci
```

This single command runs the complete CI pipeline locally:
1. Setup verification
2. RuboCop linting
3. Security scans (bundler-audit, importmap audit, Brakeman)
4. Full test suite (RSpec)

All checks must pass before committing. This ensures code quality, security, and prevents CI failures.

**Tip**: If you need to auto-fix linting issues first, run `bin/rubocop --fix` before `bin/ci`.

### Testing

```bash
# Run all tests (including system tests)
bin/rspec

# Run specific test file
bin/rspec spec/models/mtgjson/card_spec.rb

# Run specific test by line number
bin/rspec spec/models/mtgjson/card_spec.rb:24
```

**Important**: Always run the full test suite (`bin/rspec`) before committing. This includes both unit tests and system tests to ensure complete coverage.

### Code Quality

```bash
# Run RuboCop linter and auto-fix issues
bin/rubocop --fix

# Run RuboCop without auto-fix
bin/rubocop

# Run security vulnerability scans
bin/brakeman              # Static analysis for security issues
bin/bundler-audit         # Scan gems for known vulnerabilities
bin/importmap audit       # Scan JavaScript dependencies

# Run all CI checks locally
bin/ci
```

### Development

```bash
# Start development server
bin/dev

# Rails console
bin/rails console

# Database operations
bin/rails db:migrate
bin/rails db:rollback
bin/rails db:prepare      # Create database and load schema
```

### MTGJSON Database Management

```bash
# Download MTGJSON database (~500MB, required for development)
bin/rails mtgjson:download

# Display database info and statistics
bin/rails mtgjson:info

# Verify database integrity
bin/rails mtgjson:verify

# Update database (downloads latest, creates backup)
bin/rails mtgjson:refresh

# Clean up old backup files (keeps last 3)
bin/rails mtgjson:cleanup_backups

# Set up test database (required for running specs)
RAILS_ENV=test bin/rails mtgjson:setup_test
```

## Multi-Database Architecture

This application uses Rails 8.1's multi-database support with **two separate databases**:

### Primary Database (`primary`)
- Application data (user collections, items, etc.)
- Read/write operations
- Standard Rails migrations in `db/migrate/`
- Database file: `storage/development.sqlite3` (dev), `storage/test.sqlite3` (test)

### MTGJSON Database (`mtgjson`)
- External reference data (cards, sets, rulings, etc.)
- **Read-only** - enforced at model level
- No migrations (external schema)
- Database file: `storage/mtgjson.sqlite3` (dev), `storage/test_mtgjson.sqlite3` (test)
- Updated via `bin/rails mtgjson:refresh`

**Critical**: All models under `app/models/mtgjson/` inherit from `MTGJSON::Base` which:
- Connects to the separate `mtgjson` database
- Enforces read-only behavior via `before_create`, `before_update`, `before_destroy` callbacks
- Overrides `readonly?` to return `true`
- Prevents accidental writes to external reference data

## Code Structure

### Model Namespacing

The application uses ActiveSupport inflection for the `MTGJSON` acronym:

```ruby
# config/initializers/inflections.rb
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "MTGJSON"
end
```

This ensures proper constant naming:
- File: `app/models/mtgjson/card.rb` → Class: `MTGJSON::Card`
- Not: `Mtgjson::Card` or `MtgJson::Card`

### MTGJSON Models

All MTGJSON models are namespaced under `MTGJSON::` and located in `app/models/mtgjson/`:

- `MTGJSON::Base` - Abstract base class (all MTGJSON models inherit from this)
- `MTGJSON::Card` - Core card model (107K+ records, UUID primary key)
- `MTGJSON::Set` - Set information (800+ sets, string code primary key)
- `MTGJSON::Token` - Token cards
- `MTGJSON::CardIdentifier` - External platform IDs (Scryfall, TCGPlayer, etc.)
- `MTGJSON::CardLegality` - Format legalities (Commander, Modern, Standard, etc.)
- `MTGJSON::CardPrice` - Pricing data
- `MTGJSON::CardRuling` - Official rulings
- `MTGJSON::CardForeignData` - Translations
- `MTGJSON::CardPurchaseUrl` - Vendor links
- `MTGJSON::TokenIdentifier` - Token identifiers
- `MTGJSON::SetTranslation` - Set translations
- `MTGJSON::SetBoosterContent` - Booster pack information
- `MTGJSON::Meta` - Database metadata (version, date)

**Important Model Details**:

1. **Card and Set models disable STI**: The MTGJSON schema includes a `type` column that stores card/set type data, not Rails inheritance. Both models set `self.inheritance_column = nil` to prevent Rails from treating this as single-table inheritance.

2. **Meta and CardLegality have no primary key**: These models set `self.primary_key = nil` and use `self.implicit_order_column` for ordering.

3. **Associations use non-standard keys**: Many associations use `foreign_key` and `primary_key` options because MTGJSON uses UUIDs and custom codes rather than Rails conventions.

### Application Models

Application models (in `app/models/`) inherit from `ApplicationRecord` and connect to the primary database:

- `Collection` - Top-level container for organizing cards. Has many storage units and items. Full CRUD UI at `/collections`.
- `StorageUnit` - Physical storage containers (boxes, binders, decks, etc.) within a collection. Supports nested hierarchies via parent/children associations. Full CRUD UI nested under collections at `/collections/:id/storage_units`.
- `Item` - Individual cards in a collection. References MTGJSON cards via `card_uuid`. Tracks finish (foil finishes), condition, language, and optional grading score.

**Cross-database references**: To reference MTGJSON data, store the UUID and query through methods:

```ruby
class Item < ApplicationRecord
  # Store MTGJSON card UUID
  validates :card_uuid, presence: true

  # Access MTGJSON data via method
  def card
    @card ||= MTGJSON::Card.find_by(uuid: card_uuid)
  end
end
```

**Do not attempt to create foreign key constraints between databases** - they are separate SQLite files.

## Development Workflow

### Before Committing

**REQUIRED before every commit:**

```bash
bin/ci
```

This runs all CI checks locally: setup, linting, security scans, and tests. Only commit after `bin/ci` passes successfully.

**Tip**: Run `bin/rubocop --fix` first to auto-fix any linting issues, then run `bin/ci` to verify everything passes.

### Testing MTGJSON Models

MTGJSON model specs use shared examples from `spec/support/mtgjson.rb`:

```ruby
RSpec.describe MTGJSON::Card, type: :model do
  include_examples "a read-only MTGJSON model"

  # Your specific tests...
end
```

The shared examples test:
- Read-only enforcement (prevents create, update, destroy)
- `readonly?` method returns true

Tests automatically skip if the MTGJSON database is not available. Set up the test database with:

```bash
RAILS_ENV=test bin/rails mtgjson:setup_test
```

### CI/CD

GitHub Actions CI runs on pull requests and pushes to main:

1. **Security scans**: Brakeman, bundler-audit, importmap audit
2. **Linting**: RuboCop (with caching)
3. **Tests**: RSpec unit and system tests
   - MTGJSON database is cached weekly (500MB download only once per week)
   - Database is verified before tests run
   - System tests use headless Chrome via Selenium

Cache key rotates weekly: `mtgjson-{os}-weekly-{year}-W{week}`

## Technology Stack

### Frontend
- **Hotwire**: Turbo + Stimulus for reactive UI without JavaScript build step
- **Tailwind CSS**: Utility-first CSS framework
- **Importmap**: ESM import maps (no webpack/esbuild)
- **Propshaft**: Modern asset pipeline

### Backend
- **Rails 8.1**: Latest Rails with multi-database support
- **SQLite3**: Dual databases (primary + mtgjson)
- **Solid Cache**: Database-backed cache (replaces Redis for many use cases)
- **Solid Queue**: Database-backed job queue (replaces Sidekiq/Resque)
- **Solid Cable**: Database-backed Action Cable (WebSocket)
- **Puma**: Web server

### Testing
- **RSpec 8.0**: Testing framework (not Minitest)
- **Capybara**: Acceptance testing for web UI
- **Selenium WebDriver**: Browser automation for system tests

### Deployment
- **Kamal**: Docker-based deployment
- **Thruster**: HTTP/2 proxy for Puma with caching and X-Sendfile

## MTGJSON Integration Details

### Key Characteristics

- **Database Size**: ~500MB compressed download
- **Update Frequency**: MTGJSON publishes daily updates
- **Recommended Update**: Weekly via `bin/rails mtgjson:refresh`
- **Backups**: Automatic timestamped backups on refresh (keeps last 3)

### Querying Best Practices

1. **Use scopes**: Models provide scopes for common queries
   ```ruby
   MTGJSON::Card.by_name("Lightning Bolt")
   MTGJSON::Card.by_set("LEA")
   MTGJSON::Set.released
   ```

2. **Eager load associations**: Avoid N+1 queries
   ```ruby
   cards = MTGJSON::Card.includes(:set, :legalities).by_set("MH3")
   ```

3. **Paginate large result sets**: Database has 107K+ cards
   ```ruby
   MTGJSON::Card.by_color("R").limit(50).offset(0)
   ```

4. **Use `find_each` for batch processing**:
   ```ruby
   MTGJSON::Card.find_each(batch_size: 1000) do |card|
     # Process card
   end
   ```

### Read-Only Enforcement

All MTGJSON models are **strictly read-only**. Any write attempt raises `ActiveRecord::ReadOnlyRecord`:

```ruby
card = MTGJSON::Card.first
card.update(name: "Modified")  # ❌ Raises ReadOnlyRecord
card.save!                      # ❌ Raises ReadOnlyRecord
card.destroy                    # ❌ Raises ReadOnlyRecord
MTGJSON::Card.create!(...)      # ❌ Raises ReadOnlyRecord
```

This is enforced at multiple levels:
- Model callbacks (`before_create`, `before_update`, `before_destroy`)
- Instance method (`readonly?` returns `true`)
- Database configuration (`schema_dump: false` prevents schema modifications)

## Code Style

This project follows **Rails Omakase Ruby style** via `rubocop-rails-omakase`. Key points:

- Standard Ruby formatting and naming conventions
- Rails-specific best practices
- Run `bin/ci` before committing to verify all checks pass

Configuration: `.rubocop.yml` inherits from `rubocop-rails-omakase`

## Reference Documentation

- **MTGJSON Integration**: See `docs/MTGJSON_INTEGRATION.md` for comprehensive usage guide
- **MTGJSON Data Models**: https://mtgjson.com/data-models/
- **Rails Multi-Database Guide**: https://guides.rubyonrails.org/active_record_multiple_databases.html
- **Rails 8.1 Release Notes**: https://guides.rubyonrails.org/8_1_release_notes.html
