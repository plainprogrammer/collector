# frozen_string_literal: true

require "rails_helper"

RSpec.describe MTGSet, type: :model do
  describe "associations" do
    # Skipped until MTGCard model is created
    # it { is_expected.to have_many(:mtg_cards).dependent(:destroy) }
  end

  describe "validations" do
    subject { create(:mtg_set) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:code) }
  end

  describe "UUID generation" do
    it "generates a UUID for id before creation" do
      set = MTGSet.create!(code: "TST", name: "Test Set")

      expect(set.id).to be_present
      expect(set.id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
    end

    it "does not overwrite manually set id" do
      custom_id = SecureRandom.uuid
      set = MTGSet.create!(id: custom_id, code: "TST", name: "Test Set")

      expect(set.id).to eq(custom_id)
    end
  end

  describe "code uniqueness" do
    it "prevents duplicate set codes" do
      create(:mtg_set, code: "LEB")
      duplicate = build(:mtg_set, code: "LEB")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:code]).to include("has already been taken")
    end

    it "allows different sets with different codes" do
      create(:mtg_set, code: "LEB")
      different = build(:mtg_set, code: "LEA")

      expect(different).to be_valid
    end
  end
end
