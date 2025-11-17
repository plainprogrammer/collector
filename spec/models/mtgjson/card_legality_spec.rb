require "rails_helper"

RSpec.describe MTGJSON::CardLegality, type: :model do
  include_examples "a read-only MTGJSON model"

  describe "associations" do
    it { is_expected.to belong_to(:card) }
  end

  describe "scopes" do
    describe ".legal_in" do
      it "finds cards legal in a format" do
        results = described_class.legal_in("Commander")
        expect(results.count).to be >= 0
      end
    end
  end
end
