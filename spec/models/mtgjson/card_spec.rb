require "rails_helper"

RSpec.describe MTGJSON::Card, type: :model do
  include_examples "a read-only MTGJSON model"

  describe "associations" do
    it { is_expected.to belong_to(:set).optional }
    it { is_expected.to have_many(:identifiers) }
    it { is_expected.to have_many(:legalities) }
    it { is_expected.to have_many(:prices) }
    it { is_expected.to have_many(:rulings) }
    it { is_expected.to have_many(:foreign_data) }
  end

  describe "scopes" do
    describe ".by_name" do
      it "finds cards by name" do
        results = described_class.by_name("Lightning Bolt")
        expect(results.count).to be >= 0
      end
    end

    describe ".by_set" do
      it "finds cards by set code" do
        results = described_class.by_set("LEA")
        expect(results.count).to be >= 0
      end
    end

    describe ".by_color" do
      it "finds cards by color" do
        results = described_class.by_color("R")
        expect(results.count).to be >= 0
      end
    end

    describe ".by_type" do
      it "finds cards by type" do
        results = described_class.by_type("Creature")
        expect(results.count).to be >= 0
      end
    end
  end

  describe "attributes" do
    subject { described_class.first }

    it "has expected attributes" do
      skip "No cards in test database" unless subject

      expect(subject).to respond_to(:uuid)
      expect(subject).to respond_to(:name)
      expect(subject).to respond_to(:setCode)
      expect(subject.uuid).to be_present
    end
  end
end
