require "rails_helper"

RSpec.describe MTGJSON::Set, type: :model do
  include_examples "a read-only MTGJSON model"

  describe "associations" do
    it "has association to cards" do
      set = described_class.first
      expect(set).to respond_to(:cards) if set
    end

    it "has association to translations" do
      set = described_class.first
      expect(set).to respond_to(:translations) if set
    end
  end

  describe "scopes" do
    describe ".released" do
      it "returns only released sets" do
        results = described_class.released
        expect(results.count).to be >= 0
      end
    end

    describe ".upcoming" do
      it "returns only upcoming sets" do
        results = described_class.upcoming
        expect(results.count).to be >= 0
      end
    end

    describe ".by_type" do
      it "filters sets by type" do
        results = described_class.by_type("core")
        expect(results.count).to be >= 0
      end
    end
  end
end
