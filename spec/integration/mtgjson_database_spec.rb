require "rails_helper"

RSpec.describe "MTGJSON Database Integration", type: :integration do
  describe "database connection" do
    it "can connect to MTGJSON database" do
      expect { MTGJSON::Card.connection }.not_to raise_error
    end

    it "uses separate database file" do
      config = MTGJSON::Card.connection_db_config
      expect(config.database).to include("mtgjson")
      expect(config.database).not_to include("test.sqlite3")
    end
  end

  describe "data availability", :mtgjson do
    it "has cards data" do
      expect(MTGJSON::Card.count).to be > 0
    end

    it "has sets data" do
      expect(MTGJSON::Set.count).to be > 0
    end

    it "has metadata" do
      meta = MTGJSON::Meta.first
      expect(meta).to be_present
    end
  end

  describe "relationships", :mtgjson do
    it "can join cards with sets" do
      card = MTGJSON::Card.joins(:set).first
      expect(card).to be_present
      expect(card.set).to be_a(MTGJSON::Set)
    end

    it "can join cards with legalities" do
      card = MTGJSON::Card.joins(:legalities).first
      expect(card).to be_present
      expect(card.legalities).not_to be_empty
    end
  end
end
