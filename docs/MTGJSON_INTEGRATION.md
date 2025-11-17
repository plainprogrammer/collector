# MTGJSON Integration

## Overview

The Collector application integrates with the [MTGJSON](https://mtgjson.com) SQLite database to provide comprehensive Magic: The Gathering card data. MTGJSON is an open-source project that catalogs all MTG cards in a portable, structured format and is updated daily.

This integration provides read-only access to over 107,000 cards, 800+ sets, and extensive metadata including:
- Card attributes (name, mana cost, type, text, power/toughness, etc.)
- Set information (release dates, types, codes)
- Format legalities (Commander, Modern, Standard, etc.)
- Rulings and clarifications
- Foreign language printings
- Pricing data
- External platform identifiers (Scryfall, TCGPlayer, etc.)

## Architecture

### Multi-Database Setup

The MTGJSON database is configured as a separate, read-only database connection alongside the primary application database:

```yaml
# config/database.yml
development:
  primary:
    database: storage/development.sqlite3
  mtgjson:
    database: storage/mtgjson.sqlite3
    schema_dump: false  # Read-only, external data source
```

### Model Structure

All MTGJSON models inherit from `MTGJSON::Base`, which:
- Connects to the separate `mtgjson` database
- Enforces read-only behavior at the model level
- Prevents accidental writes to the external data source

```
app/models/
└── mtgjson/
    ├── base.rb                    # Abstract base class
    ├── card.rb                    # Core card model (107K+ records)
    ├── set.rb                     # Set information (800+ sets)
    ├── token.rb                   # Token cards
    ├── card_identifier.rb         # External platform IDs
    ├── card_legality.rb           # Format legalities
    ├── card_price.rb              # Pricing data
    ├── card_ruling.rb             # Official rulings
    ├── card_foreign_data.rb       # Translations
    ├── card_purchase_url.rb       # Vendor links
    ├── token_identifier.rb        # Token identifiers
    ├── set_translation.rb         # Set translations
    ├── set_booster_content.rb     # Booster info
    └── meta.rb                    # Database metadata
```

## Database Management

### Rake Tasks

The integration includes comprehensive rake tasks for managing the MTGJSON database:

```bash
# Download the latest MTGJSON database (~500MB)
bin/rails mtgjson:download

# Display database information and statistics
bin/rails mtgjson:info

# Verify database integrity
bin/rails mtgjson:verify

# Update database (downloads latest, creates backup)
bin/rails mtgjson:refresh

# Clean up old backup files (keeps last 3)
bin/rails mtgjson:cleanup_backups

# Create test database (for running specs)
RAILS_ENV=test bin/rails mtgjson:setup_test
```

### Database Information

Current database (as of 2025-11-16):
- **Version**: 5.2.2+20251116
- **Size**: ~492 MB
- **Cards**: 107,522
- **Sets**: 837
- **Tokens**: 8,049
- **Rulings**: 256,666
- **Legalities**: 107,522

## Usage Examples

### Finding Cards

```ruby
# Search by name
cards = MTGJSON::Card.by_name("Lightning Bolt")
card = MTGJSON::Card.find_by(name: "Black Lotus")

# Search by set
cards = MTGJSON::Card.by_set("LEA")  # Limited Edition Alpha

# Search by color
red_cards = MTGJSON::Card.by_color("R")

# Search by type
creatures = MTGJSON::Card.by_type("Creature")

# Find by UUID (primary key)
card = MTGJSON::Card.find("uuid-here")
```

### Accessing Card Relationships

```ruby
card = MTGJSON::Card.find_by(name: "Black Lotus")

# Get the set this card belongs to
card.set
# => #<MTGJSON::Set code: "LEA", name: "Limited Edition Alpha", ...>

# Get all legalities for this card
card.legalities
# => [#<MTGJSON::CardLegality commander: "Banned", vintage: "Restricted", ...>]

# Get pricing data
card.prices
# => [#<MTGJSON::CardPrice ...>]

# Get official rulings
card.rulings
# => [#<MTGJSON::CardRuling date: "2004-10-04", text: "...">]

# Get foreign language printings
card.foreign_data
# => [#<MTGJSON::CardForeignData language: "Japanese", name: "ブラック・ロータス", ...>]

# Get external platform identifiers
card.identifiers
# => [#<MTGJSON::CardIdentifier scryfallId: "...", tcgplayerId: "...">]
```

### Working with Sets

```ruby
# Find all released sets
released_sets = MTGJSON::Set.released

# Find upcoming sets
upcoming_sets = MTGJSON::Set.upcoming

# Find sets by year
sets_2024 = MTGJSON::Set.by_year(2024)

# Find sets by type
core_sets = MTGJSON::Set.by_type("core")

# Get all cards in a set
set = MTGJSON::Set.find_by(code: "MH3")
set.cards
# => [#<MTGJSON::Card>, #<MTGJSON::Card>, ...]
```

### Checking Legalities

```ruby
# Find all cards legal in Commander
commander_legal = MTGJSON::CardLegality.where("commander = ?", "Legal")

# Check if a specific card is legal
card = MTGJSON::Card.find_by(name: "Sol Ring")
legality = card.legalities.first
legality.commander  # => "Legal"
legality.standard   # => nil (not legal)
legality.vintage    # => "Legal"
```

### Database Metadata

```ruby
# Get current database version
MTGJSON::Meta.current_version
# => "5.2.2+20251116"

# Get last update date
MTGJSON::Meta.last_updated
# => "2025-11-16"
```

## Querying Best Practices

### Performance Tips

1. **Use specific queries**: Leverage scopes and indexes
   ```ruby
   # Good - uses index on setCode
   MTGJSON::Card.by_set("MH3")

   # Less efficient - full table scan
   MTGJSON::Card.where("setCode LIKE ?", "%MH%")
   ```

2. **Eager load associations**: Avoid N+1 queries
   ```ruby
   # Good - single query with joins
   cards = MTGJSON::Card.includes(:set, :legalities).by_set("MH3")

   # Bad - N+1 queries
   cards = MTGJSON::Card.by_set("MH3")
   cards.each { |card| card.set.name }  # Queries for each card
   ```

3. **Use pagination**: The database is large
   ```ruby
   # Good - paginate results
   MTGJSON::Card.by_color("R").limit(50).offset(0)

   # Bad - loads all red cards into memory
   MTGJSON::Card.by_color("R").to_a
   ```

4. **Cache frequently accessed data**: Use Rails caching
   ```ruby
   @sets = Rails.cache.fetch("mtgjson:released_sets", expires_in: 1.day) do
     MTGJSON::Set.released.to_a
   end
   ```

### Read-Only Enforcement

All MTGJSON models are **strictly read-only**. Any attempt to modify data will raise `ActiveRecord::ReadOnlyRecord`:

```ruby
card = MTGJSON::Card.first

# These all raise ActiveRecord::ReadOnlyRecord
card.update(name: "Modified")    # ❌ ReadOnlyRecord
card.save!                        # ❌ ReadOnlyRecord
card.destroy                      # ❌ ReadOnlyRecord
MTGJSON::Card.create!(name: "New") # ❌ ReadOnlyRecord
```

This protection ensures the integrity of the external reference data.

## Integration with Application Models

To reference MTGJSON data from your application models, store the UUID or other identifiers:

```ruby
# Application model (in primary database)
class CollectionItem < ApplicationRecord
  belongs_to :user

  # Store reference to MTGJSON card
  attribute :card_uuid, :string

  # Access the MTGJSON card data
  def card
    @card ||= MTGJSON::Card.find(card_uuid)
  end

  def card_name
    card&.name
  end

  def card_set_name
    card&.set&.name
  end
end

# Usage
item = CollectionItem.create!(
  user: current_user,
  card_uuid: "some-uuid-from-mtgjson"
)

item.card       # => #<MTGJSON::Card>
item.card_name  # => "Lightning Bolt"
```

## Updating the Database

MTGJSON publishes daily updates. To keep your data current:

```bash
# Manual update (recommended weekly)
bin/rails mtgjson:refresh

# Automated updates (optional - via cron or scheduled job)
# Add to crontab: 0 3 * * 0 cd /path/to/app && bin/rails mtgjson:refresh
```

The `refresh` task:
1. Creates a timestamped backup of the current database
2. Downloads the latest version
3. Verifies integrity
4. Keeps the last 3 backups (auto-cleanup)

## Testing

The integration includes comprehensive test coverage:

```bash
# Run all tests
bin/rspec

# Run only MTGJSON specs
bin/rspec spec/models/mtgjson/
bin/rspec spec/integration/mtgjson_database_spec.rb

# Tests automatically skip if database is unavailable
# Setup test database with:
RAILS_ENV=test bin/rails mtgjson:setup_test
```

Tests cover:
- Model read-only enforcement
- Associations and relationships
- Scopes and queries
- Database connection configuration
- Rake task functionality

## Troubleshooting

### Database Not Found

```
✗ MTGJSON database not found
```

**Solution**: Download the database
```bash
bin/rails mtgjson:download
```

### SSL Certificate Errors

If download fails with SSL errors, the rake task automatically uses `curl` which handles certificates better on most systems.

### Database Version Mismatch

If queries fail after an update, verify the database:
```bash
bin/rails mtgjson:verify
```

If verification fails, re-download:
```bash
bin/rails mtgjson:download
```

### Memory Issues with Large Queries

If you encounter memory issues:
1. Use pagination (`limit` and `offset`)
2. Process in batches (`find_each`)
3. Select only needed columns (`select`)

```ruby
# Good - processes in batches
MTGJSON::Card.find_each(batch_size: 1000) do |card|
  # Process card
end

# Good - select only needed columns
MTGJSON::Card.select(:uuid, :name, :setCode).by_set("MH3")
```

## References

- **MTGJSON Official Site**: https://mtgjson.com
- **MTGJSON Data Models**: https://mtgjson.com/data-models/
- **MTGSQLive GitHub**: https://github.com/mtgjson/mtgsqlive
- **Rails Multi-Database Guide**: https://guides.rubyonrails.org/active_record_multiple_databases.html

## License

The MTGJSON data is provided under the [MIT License](https://github.com/mtgjson/mtgjson/blob/master/LICENSE) by the MTGJSON project. This integration code is part of the Collector application and follows the application's license (GNU AGPL v3.0).
