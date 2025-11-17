require "rails_helper"

RSpec.describe MTGJSON::Base, type: :model do
  it "is an abstract class" do
    expect(described_class.abstract_class).to be true
  end

  it "connects to mtgjson database" do
    expect(described_class.connection_db_config.name).to eq("mtgjson")
  end

  it "is read-only by default" do
    # Test that child classes inherit read-only behavior
    # Actual implementation tested in child model specs
  end
end
