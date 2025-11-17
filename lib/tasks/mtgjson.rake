namespace :mtgjson do
  desc "Download the latest MTGJSON SQLite database"
  task download: :environment do
    require "net/http"
    require "fileutils"

    url = "https://mtgjson.com/api/v5/AllPrintings.sqlite"
    output_path = Rails.root.join("storage", "mtgjson.sqlite3")
    temp_path = Rails.root.join("storage", "mtgjson.sqlite3.tmp")

    puts "Downloading MTGJSON database from #{url}..."
    puts "This may take several minutes (file is ~1GB)..."

    # Create storage directory if it doesn't exist
    FileUtils.mkdir_p(Rails.root.join("storage"))

    # Download with progress
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)

      http.request(request) do |response|
        total_size = response["Content-Length"].to_i
        downloaded = 0

        File.open(temp_path, "wb") do |file|
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
    Rake::Task["mtgjson:info"].invoke
  rescue StandardError => e
    puts "\n✗ Download failed: #{e.message}"
    FileUtils.rm_f(temp_path)
    raise
  end

  desc "Display MTGJSON database information"
  task info: :environment do
    db_path = Rails.root.join("storage", "mtgjson.sqlite3")

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

  desc "Refresh MTGJSON database (download latest version)"
  task refresh: :environment do
    puts "Refreshing MTGJSON database..."

    # Backup current database
    current_db = Rails.root.join("storage", "mtgjson.sqlite3")
    if File.exist?(current_db)
      backup_path = Rails.root.join("storage", "mtgjson.sqlite3.backup.#{Time.now.to_i}")
      puts "Creating backup: #{backup_path}"
      FileUtils.cp(current_db, backup_path)
    end

    # Download new version
    Rake::Task["mtgjson:download"].invoke

    puts "✓ Refresh complete"
  rescue StandardError => e
    puts "✗ Refresh failed: #{e.message}"

    # Restore from backup if available
    backup_files = Dir.glob(Rails.root.join("storage", "mtgjson.sqlite3.backup.*"))
    if backup_files.any?
      latest_backup = backup_files.max_by { |f| File.mtime(f) }
      puts "Restoring from backup: #{latest_backup}"
      FileUtils.cp(latest_backup, current_db)
    end

    raise
  end

  desc "Clean up old MTGJSON database backups (keep last 3)"
  task cleanup_backups: :environment do
    backup_pattern = Rails.root.join("storage", "mtgjson.sqlite3.backup.*")
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

  desc "Verify database integrity"
  task verify: :environment do
    db_path = Rails.root.join("storage", "mtgjson.sqlite3")

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
      if MTGJSON::Base.connection.table_exists?(table)
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

  desc "Setup test database with sample data"
  task setup_test: :environment do
    unless Rails.env.test?
      puts "✗ This task should only run in test environment"
      exit 1
    end

    source_db = Rails.root.join("storage", "mtgjson.sqlite3")
    test_db = Rails.root.join("storage", "test_mtgjson.sqlite3")

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
