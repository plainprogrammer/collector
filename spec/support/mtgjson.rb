# Shared configuration for MTGJSON specs
RSpec.configure do |config|
  config.before(:suite) do
    # Verify test database exists
    test_db_path = Rails.root.join("storage", "test_mtgjson.sqlite3")
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
    test_db_path = Rails.root.join("storage", "test_mtgjson.sqlite3")
    if File.exist?(test_db_path)
      example.run
    else
      skip "MTGJSON test database not available"
    end
  end
end

# Shared examples for read-only models
RSpec.shared_examples "a read-only MTGJSON model" do
  let(:model_class) { described_class }

  it "is read-only" do
    instance = model_class.first
    expect(instance).to be_readonly if instance
  end

  it "prevents updates" do
    instance = model_class.first
    skip "No records in database" unless instance

    # Try to update - will fail due to read-only
    expect {
      instance.save!
    }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "prevents deletion" do
    instance = model_class.first
    skip "No records in database" unless instance

    expect {
      instance.destroy
    }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "prevents creation" do
    # Skip if no records to infer attributes from
    skip "No records in database" if model_class.count == 0

    # Try to create with minimal attributes - will fail due to read-only or validation
    # Some models may fail validation first (e.g., required associations)
    expect {
      model_class.create!
    }.to raise_error(StandardError)

    # Verify model is configured as readonly
    instance = model_class.new
    expect(instance).to be_readonly
  end
end
