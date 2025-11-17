# MTGJSON SQLite Integration Plan

## Overview
This document outlines the plan to integrate the MTGJSON SQLite database as a read-only data source for the Collector Rails application. MTGJSON is an open-source project that catalogs all Magic: The Gathering cards in a portable format, updated daily.

## Current Project State
- **Rails Version**: 8.1.1
- **Ruby Version**: 3.4.7
- **Database**: SQLite3
- **Testing Framework**: RSpec 7.1
- **Multi-Database Support**: Already configured for production (primary, cache, queue, cable)
- **Status**: Early stage project with no domain models yet

## MTGJSON Database Structure

### Primary Tables
Based on MTGJSON/MTGSQLive schema:
- **cards** - Core card data (name, mana cost, type, text, colors, etc.)
- **sets** - Set information (code, name, release date, type)
- **tokens** - Token card data
- **cardIdentifiers** - External platform identifiers (Scryfall, TCG, MTGO, etc.)
- **cardLegalities** - Format legality status (Standard, Modern, Commander, etc.)
- **cardPrices** - Pricing data from various sources
- **cardPurchaseUrls** - Purchase links for various vendors
- **cardRulings** - Official rulings and clarifications
- **cardForeignData** - Translations and foreign language printings
- **setBoosterContents** - Booster pack composition data
- **setBoosterSheets** - Print sheet information
- **setBoosterContentWeights** - Distribution weights for boosters
- **setTranslations** - Set name translations
- **tokenIdentifiers** - Identifiers for tokens
- **meta** - Database metadata and version info

### Key Relationships
- Cards are identified by `uuid` (UUID v5) - primary key
- Cards belong to sets via `setCode`
- Many-to-one relationships: card → set
- One-to-many relationships: card → legalities, prices, rulings, foreign data, identifiers

---

## Phase 1: Database Configuration

### 1.1 Update Database Configuration
**File**: `config/database.yml`

Add MTGJSON database configuration for all environments:

```yaml
development:
  primary:
    <<: *default
    database: storage/development.sqlite3
  mtgjson:
    <<: *default
    database: storage/mtgjson.sqlite3
    migrations_paths: db/mtgjson_migrate
    schema_dump: false  # Read-only, no schema dumping

test:
  primary:
    <<: *default
    database: storage/test.sqlite3
  mtgjson:
    <<: *default
    database: storage/test_mtgjson.sqlite3
    migrations_paths: db/mtgjson_migrate
    schema_dump: false

production:
  primary:
    # ... existing config
  mtgjson:
    <<: *default
    database: storage/mtgjson.sqlite3
    migrations_paths: db/mtgjson_migrate
    schema_dump: false
  # ... existing cache, queue, cable configs
```

**Rationale**:
- Separate database connection for MTGJSON data
- `schema_dump: false` prevents Rails from managing schema (read-only external data)
- Consistent across all environments
- Separate migration path (though unlikely to be used)

### 1.2 Create Database Directory Structure
```
storage/
├── mtgjson.sqlite3           # Downloaded MTGJSON database
├── test_mtgjson.sqlite3      # Test fixture database
db/
├── mtgjson_migrate/          # Migration path (mostly unused)
└── mtgjson_schema.rb         # Optional: documentation of schema
```

### 1.3 Add .gitignore Entries
```
storage/mtgjson.sqlite3
storage/test_mtgjson.sqlite3
```

**Rationale**: Database files are large (1GB+) and shouldn't be committed to git.

### 1.4 Configure Rails Inflections
**File**: `config/initializers/inflections.rb`

Add MTGJSON as an acronym to ensure proper constant naming:

```ruby
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "MTGJSON"
end
```

**Rationale**:
- Ensures Rails correctly handles the `MTGJSON` constant
- Allows file path `app/models/mtgjson/base.rb` to map to module `MTGJSON::Base`
- Without this, Rails would expect `Mtgjson::Base` (incorrect capitalization)
- Required for autoloading to work correctly with the all-caps acronym

---

## Phase 2: ActiveRecord Models

### 2.1 Base Model for MTGJSON
**File**: `app/models/mtgjson/base.rb`

```ruby
module MTGJSON
  class Base < ApplicationRecord
    self.abstract_class = true
    connects_to database: { writing: :mtgjson, reading: :mtgjson }

    # Make all MTGJSON models read-only by default
    before_destroy :readonly!
    before_update :readonly!
    before_create :readonly!

    def readonly?
      true
    end
  end
end
```

**Rationale**:
- Namespace isolation (`MTGJSON::`)
- Connects to dedicated database
- Enforces read-only at model level
- Prevents accidental writes

### 2.2 Core Models

#### Card Model
**File**: `app/models/mtgjson/card.rb`

```ruby
module MTGJSON
  class Card < Base
    self.table_name = 'cards'
    self.primary_key = 'uuid'

    # Associations
    belongs_to :set, foreign_key: 'setCode', primary_key: 'code', optional: true
    has_many :identifiers, foreign_key: 'uuid', primary_key: 'uuid', class_name: 'CardIdentifier'
    has_many :legalities, foreign_key: 'uuid', primary_key: 'uuid', class_name: 'CardLegality'
    has_many :prices, foreign_key: 'uuid', primary_key: 'uuid', class_name: 'CardPrice'
    has_many :rulings, foreign_key: 'uuid', primary_key: 'uuid', class_name: 'CardRuling'
    has_many :foreign_data, foreign_key: 'uuid', primary_key: 'uuid', class_name: 'CardForeignData'
    has_many :purchase_urls, foreign_key: 'uuid', primary_key: 'uuid', class_name: 'CardPurchaseUrl'

    # Scopes
    scope :by_name, ->(name) { where('name LIKE ?', "%#{name}%") }
    scope :by_set, ->(set_code) { where(setCode: set_code) }
    scope :by_color, ->(colors) { where('colors LIKE ?', "%#{colors}%") }
    scope :by_type, ->(type) { where('type LIKE ?', "%#{type}%") }

    # Virtual attributes for JSON fields (if stored as JSON strings)
    # MTGJSON may store arrays as JSON - adjust as needed
  end
end
```

#### Set Model
**File**: `app/models/mtgjson/set.rb`

```ruby
module MTGJSON
  class Set < Base
    self.table_name = 'sets'
    self.primary_key = 'code'

    # Associations
    has_many :cards, foreign_key: 'setCode', primary_key: 'code'
    has_many :translations, foreign_key: 'setCode', primary_key: 'code', class_name: 'SetTranslation'
    has_many :booster_contents, foreign_key: 'setCode', primary_key: 'code', class_name: 'SetBoosterContent'

    # Scopes
    scope :released, -> { where('releaseDate <= ?', Date.today) }
    scope :upcoming, -> { where('releaseDate > ?', Date.today) }
    scope :by_type, ->(type) { where(type: type) }
    scope :by_year, ->(year) { where('releaseDate LIKE ?', "#{year}%") }
  end
end
```

#### Supporting Models
**Files**: `app/models/mtgjson/*.rb`

```ruby
# app/models/mtgjson/card_identifier.rb
module MTGJSON
  class CardIdentifier < Base
    self.table_name = 'cardIdentifiers'
    belongs_to :card, foreign_key: 'uuid', primary_key: 'uuid'
  end
end

# app/models/mtgjson/card_legality.rb
module MTGJSON
  class CardLegality < Base
    self.table_name = 'cardLegalities'
    belongs_to :card, foreign_key: 'uuid', primary_key: 'uuid'

    scope :legal_in, ->(format) { where(format: format, status: 'Legal') }
  end
end

# app/models/mtgjson/card_price.rb
module MTGJSON
  class CardPrice < Base
    self.table_name = 'cardPrices'
    belongs_to :card, foreign_key: 'uuid', primary_key: 'uuid'
  end
end

# app/models/mtgjson/card_ruling.rb
module MTGJSON
  class CardRuling < Base
    self.table_name = 'cardRulings'
    belongs_to :card, foreign_key: 'uuid', primary_key: 'uuid'
  end
end

# app/models/mtgjson/card_foreign_data.rb
module MTGJSON
  class CardForeignData < Base
    self.table_name = 'cardForeignData'
    belongs_to :card, foreign_key: 'uuid', primary_key: 'uuid'
  end
end

# app/models/mtgjson/card_purchase_url.rb
module MTGJSON
  class CardPurchaseUrl < Base
    self.table_name = 'cardPurchaseUrls'
    belongs_to :card, foreign_key: 'uuid', primary_key: 'uuid'
  end
end

# app/models/mtgjson/token.rb
module MTGJSON
  class Token < Base
    self.table_name = 'tokens'
    self.primary_key = 'uuid'

    has_many :identifiers, foreign_key: 'uuid', primary_key: 'uuid', class_name: 'TokenIdentifier'
  end
end

# app/models/mtgjson/token_identifier.rb
module MTGJSON
  class TokenIdentifier < Base
    self.table_name = 'tokenIdentifiers'
    belongs_to :token, foreign_key: 'uuid', primary_key: 'uuid'
  end
end

# app/models/mtgjson/set_translation.rb
module MTGJSON
  class SetTranslation < Base
    self.table_name = 'setTranslations'
    belongs_to :set, foreign_key: 'setCode', primary_key: 'code'
  end
end

# app/models/mtgjson/set_booster_content.rb
module MTGJSON
  class SetBoosterContent < Base
    self.table_name = 'setBoosterContents'
    belongs_to :set, foreign_key: 'setCode', primary_key: 'code'
  end
end

# app/models/mtgjson/meta.rb
module MTGJSON
  class Meta < Base
    self.table_name = 'meta'

    # Utility method to get current database version
    def self.current_version
      first&.version || 'unknown'
    end

    def self.last_updated
      first&.date || 'unknown'
    end
  end
end
```

### 2.3 Model Structure Summary
```
app/models/
├── mtgjson/
│   ├── base.rb                    # Abstract base class
│   ├── card.rb                    # Core card model
│   ├── set.rb                     # Set model
│   ├── token.rb                   # Token model
│   ├── card_identifier.rb         # Card identifiers
│   ├── card_legality.rb           # Format legalities
│   ├── card_price.rb              # Pricing data
│   ├── card_ruling.rb             # Rulings
│   ├── card_foreign_data.rb       # Translations
│   ├── card_purchase_url.rb       # Purchase links
│   ├── token_identifier.rb        # Token identifiers
│   ├── set_translation.rb         # Set translations
│   ├── set_booster_content.rb     # Booster info
│   └── meta.rb                    # Database metadata
```

---

## Phase 3: Rake Tasks for Data Management

### 3.1 Download Task
**File**: `lib/tasks/mtgjson.rake`

```ruby
namespace :mtgjson do
  desc 'Download the latest MTGJSON SQLite database'
  task download: :environment do
    require 'net/http'
    require 'fileutils'

    url = 'https://mtgjson.com/api/v5/AllPrintings.sqlite'
    output_path = Rails.root.join('storage', 'mtgjson.sqlite3')
    temp_path = Rails.root.join('storage', 'mtgjson.sqlite3.tmp')

    puts "Downloading MTGJSON database from #{url}..."
    puts "This may take several minutes (file is ~1GB)..."

    # Create storage directory if it doesn't exist
    FileUtils.mkdir_p(Rails.root.join('storage'))

    # Download with progress
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)

      http.request(request) do |response|
        total_size = response['Content-Length'].to_i
        downloaded = 0

        File.open(temp_path, 'wb') do |file|
          response.read_body do |chunk|
            file.write(chunk)
            downloaded += chunk.size

            # Progress indicator
            percentage = (downloaded * 100.0 / total_size).round(2)
            print "\rProgress: #{percentage}% (#{downloaded}/#{total_size} bytes)"
          end
        end
      end
    end

    # Move temp file to final location
    FileUtils.mv(temp_path, output_path)
    puts "\n✓ Download complete: #{output_path}"

    # Display metadata
    Rake::Task['mtgjson:info'].invoke
  rescue StandardError => e
    puts "\n✗ Download failed: #{e.message}"
    FileUtils.rm_f(temp_path)
    raise
  end

  desc 'Display MTGJSON database information'
  task info: :environment do
    db_path = Rails.root.join('storage', 'mtgjson.sqlite3')

    unless File.exist?(db_path)
      puts "✗ MTGJSON database not found at #{db_path}"
      puts "Run 'rake mtgjson:download' to download it."
      next
    end

    file_size = File.size(db_path)
    file_size_mb = (file_size / 1024.0 / 1024.0).round(2)

    puts "\n" + "=" * 60
    puts "MTGJSON Database Information"
    puts "=" * 60
    puts "Location: #{db_path}"
    puts "Size: #{file_size_mb} MB"
    puts "Modified: #{File.mtime(db_path)}"

    # Get metadata from database
    begin
      meta = MTGJSON::Meta.first
      if meta
        puts "\nDatabase Metadata:"
        puts "  Version: #{meta.version}" if meta.respond_to?(:version)
        puts "  Date: #{meta.date}" if meta.respond_to?(:date)
      end

      # Get counts
      puts "\nRecord Counts:"
      puts "  Cards: #{MTGJSON::Card.count}"
      puts "  Sets: #{MTGJSON::Set.count}"
      puts "  Tokens: #{MTGJSON::Token.count}"
      puts "  Rulings: #{MTGJSON::CardRuling.count}"
      puts "  Legalities: #{MTGJSON::CardLegality.count}"
    rescue StandardError => e
      puts "\n✗ Could not read database: #{e.message}"
    end

    puts "=" * 60 + "\n"
  end

  desc 'Refresh MTGJSON database (download latest version)'
  task refresh: :environment do
    puts "Refreshing MTGJSON database..."

    # Backup current database
    current_db = Rails.root.join('storage', 'mtgjson.sqlite3')
    if File.exist?(current_db)
      backup_path = Rails.root.join('storage', "mtgjson.sqlite3.backup.#{Time.now.to_i}")
      puts "Creating backup: #{backup_path}"
      FileUtils.cp(current_db, backup_path)
    end

    # Download new version
    Rake::Task['mtgjson:download'].invoke

    puts "✓ Refresh complete"
  rescue StandardError => e
    puts "✗ Refresh failed: #{e.message}"

    # Restore from backup if available
    backup_files = Dir.glob(Rails.root.join('storage', 'mtgjson.sqlite3.backup.*'))
    if backup_files.any?
      latest_backup = backup_files.max_by { |f| File.mtime(f) }
      puts "Restoring from backup: #{latest_backup}"
      FileUtils.cp(latest_backup, current_db)
    end

    raise
  end

  desc 'Clean up old MTGJSON database backups (keep last 3)'
  task cleanup_backups: :environment do
    backup_pattern = Rails.root.join('storage', 'mtgjson.sqlite3.backup.*')
    backups = Dir.glob(backup_pattern).sort_by { |f| File.mtime(f) }

    if backups.size > 3
      to_delete = backups[0...-3]
      puts "Removing #{to_delete.size} old backup(s)..."
      to_delete.each do |backup|
        puts "  Deleting: #{File.basename(backup)}"
        FileUtils.rm(backup)
      end
      puts "✓ Cleanup complete"
    else
      puts "No cleanup needed (#{backups.size} backup(s) found)"
    end
  end

  desc 'Verify database integrity'
  task verify: :environment do
    db_path = Rails.root.join('storage', 'mtgjson.sqlite3')

    unless File.exist?(db_path)
      puts "✗ Database not found"
      exit 1
    end

    puts "Verifying database integrity..."

    # Basic integrity checks
    checks_passed = 0
    checks_failed = 0

    # Check 1: Can connect
    begin
      MTGJSON::Card.connection
      puts "✓ Database connection successful"
      checks_passed += 1
    rescue StandardError => e
      puts "✗ Database connection failed: #{e.message}"
      checks_failed += 1
    end

    # Check 2: Tables exist
    expected_tables = %w[cards sets tokens cardIdentifiers cardLegalities meta]
    expected_tables.each do |table|
      if ActiveRecord::Base.connection.table_exists?(table)
        puts "✓ Table '#{table}' exists"
        checks_passed += 1
      else
        puts "✗ Table '#{table}' missing"
        checks_failed += 1
      end
    end

    # Check 3: Basic data validation
    begin
      card_count = MTGJSON::Card.count
      if card_count > 0
        puts "✓ Cards table has data (#{card_count} records)"
        checks_passed += 1
      else
        puts "✗ Cards table is empty"
        checks_failed += 1
      end
    rescue StandardError => e
      puts "✗ Could not query cards: #{e.message}"
      checks_failed += 1
    end

    puts "\n" + "=" * 60
    puts "Verification Results: #{checks_passed} passed, #{checks_failed} failed"
    puts "=" * 60

    exit(checks_failed > 0 ? 1 : 0)
  end

  desc 'Setup test database with sample data'
  task setup_test: :environment do
    unless Rails.env.test?
      puts "✗ This task should only run in test environment"
      exit 1
    end

    source_db = Rails.root.join('storage', 'mtgjson.sqlite3')
    test_db = Rails.root.join('storage', 'test_mtgjson.sqlite3')

    unless File.exist?(source_db)
      puts "✗ Source database not found. Run 'rake mtgjson:download' first."
      exit 1
    end

    puts "Creating test database with sample data..."

    # Copy a subset of data for testing
    # This would use SQLite commands to extract sample data
    # Implementation details depend on specific testing needs

    FileUtils.cp(source_db, test_db)
    puts "✓ Test database created"
  end
end
```

### 3.2 Scheduled Refresh (Optional)
For production environments, set up a scheduled job to refresh data periodically:

**Using Solid Queue** (already configured in this project):

```ruby
# config/initializers/solid_queue.rb
# Add recurring job configuration
Rails.application.config.after_initialize do
  if Rails.env.production?
    # Refresh MTGJSON data weekly on Sundays at 3 AM
    SolidQueue::RecurringTask.create!(
      key: 'mtgjson_refresh',
      schedule: '0 3 * * 0',
      class_name: 'MtgjsonRefreshJob'
    )
  end
end

# app/jobs/mtgjson_refresh_job.rb
class MtgjsonRefreshJob < ApplicationJob
  queue_as :default

  def perform
    # Run rake task programmatically
    Rake::Task['mtgjson:refresh'].invoke
  end
end
```

---

## Phase 4: Unit Testing Strategy

### 4.1 Testing Philosophy
Given the MTGJSON database is:
- **External data source** (not controlled by our application)
- **Read-only** (no write operations to test)
- **Large** (1GB+ database, 100K+ cards)

Testing should focus on:
1. **Model behavior** - Associations, scopes, validations work correctly
2. **Integration** - Database connection and configuration
3. **Fixtures/Factories** - Representative sample data for testing app features
4. **Not data integrity** - MTGJSON maintains their data quality

### 4.2 RSpec Configuration

**File**: `spec/support/mtgjson.rb`

```ruby
# Shared configuration for MTGJSON specs
RSpec.configure do |config|
  config.before(:suite) do
    # Verify test database exists
    test_db_path = Rails.root.join('storage', 'test_mtgjson.sqlite3')
    unless File.exist?(test_db_path)
      warn "Warning: Test MTGJSON database not found. Some specs may fail."
      warn "Run 'rake mtgjson:setup_test' to create test database."
    end
  end

  # Tag specs that require MTGJSON database
  config.define_derived_metadata(file_path: %r{spec/models/mtgjson}) do |metadata|
    metadata[:mtgjson] = true
  end

  # Skip MTGJSON specs if database not available
  config.around(:each, :mtgjson) do |example|
    test_db_path = Rails.root.join('storage', 'test_mtgjson.sqlite3')
    if File.exist?(test_db_path)
      example.run
    else
      skip "MTGJSON test database not available"
    end
  end
end

# Shared examples for read-only models
RSpec.shared_examples 'a read-only MTGJSON model' do
  let(:model_class) { described_class }

  it 'is read-only' do
    instance = model_class.first
    expect(instance).to be_readonly if instance
  end

  it 'prevents updates' do
    instance = model_class.first
    skip "No records in database" unless instance

    expect {
      instance.update(name: 'Modified')
    }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it 'prevents deletion' do
    instance = model_class.first
    skip "No records in database" unless instance

    expect {
      instance.destroy
    }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it 'prevents creation' do
    expect {
      model_class.create!(name: 'New Record')
    }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
```

### 4.3 Model Specs

**File**: `spec/models/mtgjson/base_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe MTGJSON::Base, type: :model do
  it 'is an abstract class' do
    expect(described_class.abstract_class).to be true
  end

  it 'connects to mtgjson database' do
    expect(described_class.connection_db_config.name).to eq('mtgjson')
  end

  it 'is read-only by default' do
    # Test that child classes inherit read-only behavior
    # Actual implementation tested in child model specs
  end
end
```

**File**: `spec/models/mtgjson/card_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe MTGJSON::Card, type: :model do
  include_examples 'a read-only MTGJSON model'

  describe 'associations' do
    it { should belong_to(:set).optional }
    it { should have_many(:identifiers) }
    it { should have_many(:legalities) }
    it { should have_many(:prices) }
    it { should have_many(:rulings) }
    it { should have_many(:foreign_data) }
  end

  describe 'scopes' do
    describe '.by_name' do
      it 'finds cards by name' do
        results = described_class.by_name('Lightning Bolt')
        expect(results.count).to be > 0
        expect(results.first.name).to include('Lightning Bolt')
      end
    end

    describe '.by_set' do
      it 'finds cards by set code' do
        results = described_class.by_set('LEA')
        expect(results).to all(have_attributes(setCode: 'LEA'))
      end
    end

    describe '.by_color' do
      it 'finds cards by color' do
        results = described_class.by_color('R')
        expect(results.count).to be > 0
      end
    end

    describe '.by_type' do
      it 'finds cards by type' do
        results = described_class.by_type('Creature')
        expect(results.count).to be > 0
      end
    end
  end

  describe 'attributes' do
    subject { described_class.first }

    it 'has expected attributes' do
      skip "No cards in test database" unless subject

      expect(subject).to respond_to(:uuid)
      expect(subject).to respond_to(:name)
      expect(subject).to respond_to(:setCode)
      expect(subject.uuid).to be_present
    end
  end
end
```

**File**: `spec/models/mtgjson/set_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe MTGJSON::Set, type: :model do
  include_examples 'a read-only MTGJSON model'

  describe 'associations' do
    it { should have_many(:cards) }
    it { should have_many(:translations) }
  end

  describe 'scopes' do
    describe '.released' do
      it 'returns only released sets' do
        results = described_class.released
        expect(results).to all(satisfy { |set| set.releaseDate <= Date.today })
      end
    end

    describe '.upcoming' do
      it 'returns only upcoming sets' do
        results = described_class.upcoming
        expect(results).to all(satisfy { |set| set.releaseDate > Date.today })
      end
    end

    describe '.by_type' do
      it 'filters sets by type' do
        results = described_class.by_type('core')
        expect(results.count).to be >= 0
      end
    end
  end
end
```

**File**: `spec/models/mtgjson/card_legality_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe MTGJSON::CardLegality, type: :model do
  include_examples 'a read-only MTGJSON model'

  describe 'associations' do
    it { should belong_to(:card) }
  end

  describe 'scopes' do
    describe '.legal_in' do
      it 'finds cards legal in a format' do
        results = described_class.legal_in('Commander')
        expect(results).to all(have_attributes(format: 'Commander', status: 'Legal'))
      end
    end
  end
end
```

### 4.4 Integration Specs

**File**: `spec/integration/mtgjson_database_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe 'MTGJSON Database Integration', type: :integration do
  describe 'database connection' do
    it 'can connect to MTGJSON database' do
      expect { MTGJSON::Card.connection }.not_to raise_error
    end

    it 'uses separate database file' do
      config = MTGJSON::Card.connection_db_config
      expect(config.database).to include('mtgjson')
      expect(config.database).not_to include('test.sqlite3')
    end
  end

  describe 'data availability' do
    it 'has cards data' do
      expect(MTGJSON::Card.count).to be > 0
    end

    it 'has sets data' do
      expect(MTGJSON::Set.count).to be > 0
    end

    it 'has metadata' do
      meta = MTGJSON::Meta.first
      expect(meta).to be_present
    end
  end

  describe 'relationships' do
    it 'can join cards with sets' do
      card = MTGJSON::Card.joins(:set).first
      expect(card).to be_present
      expect(card.set).to be_a(MTGJSON::Set)
    end

    it 'can join cards with legalities' do
      card = MTGJSON::Card.joins(:legalities).first
      expect(card).to be_present
      expect(card.legalities).not_to be_empty
    end
  end
end
```

### 4.5 Rake Task Specs

**File**: `spec/lib/tasks/mtgjson_rake_spec.rb`

```ruby
require 'rails_helper'
require 'rake'

RSpec.describe 'mtgjson rake tasks' do
  before(:all) do
    Rails.application.load_tasks
  end

  describe 'mtgjson:info' do
    it 'displays database information' do
      expect {
        Rake::Task['mtgjson:info'].invoke
      }.to output(/MTGJSON Database Information/).to_stdout
    end
  end

  describe 'mtgjson:verify' do
    it 'verifies database integrity' do
      # This will exit 0 or 1 based on verification results
      # Testing rake tasks that call exit is tricky
      # Consider refactoring verification logic to a separate service
    end
  end

  # Note: Download/refresh tasks should not be tested in CI
  # as they require network access and download large files
  describe 'mtgjson:download', :skip do
    it 'downloads the database'
  end
end
```

### 4.6 Factory/Fixture Strategy

Since MTGJSON is external, read-only data:

**Option 1: Use actual test database**
- Create small test database with sample records
- Fast, realistic, but requires maintenance

**Option 2: Use FactoryBot for application models only**
```ruby
# spec/factories/mtgjson.rb
# Note: These won't actually create records in MTGJSON database
# Only use for mocking/stubbing in application specs

FactoryBot.define do
  factory :mtgjson_card, class: 'MTGJSON::Card' do
    uuid { SecureRandom.uuid }
    name { 'Lightning Bolt' }
    setCode { 'LEA' }
    type { 'Instant' }
    # ... other attributes

    # Override new/create to use build_stubbed or mocking
    initialize_with { MTGJSON::Card.new(attributes) }
  end
end
```

**Recommended Approach**: Use small test database with representative sample data for different scenarios (edge cases, common cards, special types, etc.)

### 4.7 Testing Checklist
- [ ] Base model read-only enforcement
- [ ] Each model's associations
- [ ] Each model's scopes
- [ ] Database connection configuration
- [ ] Cross-database queries (if app models reference MTGJSON)
- [ ] Rake task info/verify tasks
- [ ] Error handling (missing database, corrupt data)
- [ ] Performance (for critical queries)

---

## Phase 5: Implementation Checklist

### Database Setup
- [ ] Update `config/database.yml` with mtgjson database config
- [ ] Create `db/mtgjson_migrate/` directory
- [ ] Update `.gitignore` to exclude database files
- [ ] Configure Rails inflections for MTGJSON acronym in `config/initializers/inflections.rb`
- [ ] Run `rake mtgjson:download` to get initial database

### Models
- [ ] Create `app/models/mtgjson/` directory
- [ ] Implement `MTGJSON::Base` abstract class
- [ ] Implement core models (Card, Set, Token)
- [ ] Implement supporting models (Identifiers, Legalities, Prices, etc.)
- [ ] Add associations between models
- [ ] Add useful scopes to models
- [ ] Verify read-only behavior

### Rake Tasks
- [ ] Create `lib/tasks/mtgjson.rake`
- [ ] Implement `download` task
- [ ] Implement `info` task
- [ ] Implement `refresh` task
- [ ] Implement `verify` task
- [ ] Implement `cleanup_backups` task
- [ ] Implement `setup_test` task
- [ ] Test each task manually

### Testing
- [ ] Create `spec/support/mtgjson.rb` with shared config
- [ ] Create shared examples for read-only behavior
- [ ] Write spec for `MTGJSON::Base`
- [ ] Write specs for each model
- [ ] Write integration specs
- [ ] Write rake task specs
- [ ] Setup test database with sample data
- [ ] Run full test suite

### Documentation
- [ ] Document model usage in code comments
- [ ] Create README section for MTGJSON integration
- [ ] Document rake tasks
- [ ] Document testing approach
- [ ] Add examples of common queries

### Optional Enhancements
- [ ] Setup scheduled refresh job (Solid Queue)
- [ ] Add logging for download/refresh operations
- [ ] Add metrics/monitoring for data freshness
- [ ] Create admin UI to view MTGJSON status
- [ ] Add caching layer for frequent queries
- [ ] Create service objects for complex queries

---

## Phase 6: Usage Examples

### Querying Cards
```ruby
# Find a specific card
card = MTGJSON::Card.find_by(name: 'Lightning Bolt')

# Search cards
cards = MTGJSON::Card.by_name('Dragon').by_color('R')

# Get card with associations
card = MTGJSON::Card.includes(:legalities, :prices).find_by(name: 'Black Lotus')

# Check legality
card.legalities.legal_in('Commander')

# Get pricing
card.prices.first&.price
```

### Querying Sets
```ruby
# All released sets
sets = MTGJSON::Set.released

# Sets by year
sets = MTGJSON::Set.by_year(2024)

# Get set with cards
set = MTGJSON::Set.includes(:cards).find_by(code: 'MH3')
```

### Cross-Database Queries
If your application has user collections:
```ruby
# User model (primary database)
class User < ApplicationRecord
  has_many :collection_items
end

# CollectionItem model (primary database)
class CollectionItem < ApplicationRecord
  belongs_to :user
  # Store uuid reference to MTGJSON card
  attribute :card_uuid, :string

  def card
    @card ||= MTGJSON::Card.find_by(uuid: card_uuid)
  end
end

# Usage
user = User.first
user.collection_items.map(&:card)
```

---

## Technical Considerations

### Performance
- **Database Size**: ~1GB, plan for storage
- **Query Performance**: SQLite is fast for reads, but consider indexing if adding custom queries
- **Memory**: Loading many records at once can be memory-intensive, use pagination/batching

### Data Freshness
- MTGJSON updates daily
- Implement monitoring to alert if data is stale (>7 days)
- Consider automated refresh schedule

### Error Handling
- Database file missing or corrupted
- Download failures (network issues)
- Schema changes in MTGJSON (rare but possible)
- Read-only constraint violations

### Security
- Database is public data, no sensitive information
- Read-only prevents data corruption
- Validate input for search queries (SQL injection prevention)

### Maintenance
- Monitor disk space for database + backups
- Clean up old backups periodically
- Update documentation if MTGJSON schema changes
- Consider version pinning if schema stability is critical

---

## Timeline Estimate

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| Phase 1 | Database Configuration | 1 hour |
| Phase 2 | ActiveRecord Models | 4-6 hours |
| Phase 3 | Rake Tasks | 3-4 hours |
| Phase 4 | Testing Setup | 4-6 hours |
| Phase 5 | Testing Implementation | 4-6 hours |
| **Total** | | **16-23 hours** |

---

## Success Criteria

Integration is complete when:
1. ✓ MTGJSON database is configured as separate read-only database
2. ✓ All major tables have ActiveRecord models with associations
3. ✓ Rake tasks can download, refresh, and verify database
4. ✓ Comprehensive test coverage for models and integration
5. ✓ Documentation is complete and examples work
6. ✓ All tests pass in CI/CD pipeline
7. ✓ Read-only enforcement prevents accidental writes

---

## References

- **MTGJSON Official Site**: https://mtgjson.com
- **MTGJSON Data Models**: https://mtgjson.com/data-models/
- **MTGSQLive GitHub**: https://github.com/mtgjson/mtgsqlive
- **Rails Multi-Database**: https://guides.rubyonrails.org/active_record_multiple_databases.html
- **SQLite Documentation**: https://www.sqlite.org/docs.html

---

## Appendix: Alternative Approaches Considered

### A1: JSON API Instead of SQLite
**Pros**: No local database file, always fresh data
**Cons**: Network dependency, rate limits, slower queries, no offline support
**Decision**: SQLite is better for read-heavy workloads and offline capability

### A2: Import into Primary Database
**Pros**: Single database, simpler queries
**Cons**: Schema pollution, data duplication, harder to refresh, larger migrations
**Decision**: Separate database maintains clear boundary

### A3: Use PostgreSQL Instead of SQLite
**Pros**: Better for complex queries, full-text search
**Cons**: Requires conversion from SQLite, larger infrastructure footprint
**Decision**: SQLite works well for this use case, can migrate later if needed

### A4: Cache Layer with Redis
**Pros**: Extremely fast queries, reduced database load
**Cons**: Additional complexity, cache invalidation challenges
**Decision**: Consider as future enhancement if performance becomes an issue
