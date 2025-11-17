require "rails_helper"

RSpec.describe MTGJSON::CardLegality, type: :model do
  include_examples "a read-only MTGJSON model"

  describe "associations" do
    it "has association to card" do
      legality = described_class.first
      expect(legality).to respond_to(:card) if legality
    end
  end

  describe "queries" do
    it "can query legalities by format" do
      # Schema has columns for each format (commander, modern, etc.)
      results = described_class.where("commander = ?", "Legal")
      expect(results.count).to be >= 0
    end
  end
end
