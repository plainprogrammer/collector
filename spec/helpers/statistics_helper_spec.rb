require "rails_helper"

RSpec.describe StatisticsHelper, type: :helper do
  describe "#stat_color_class" do
    it "returns correct class for colors" do
      expect(helper.stat_color_class("R")).to include("red")
      expect(helper.stat_color_class("U")).to include("blue")
      expect(helper.stat_color_class("G")).to include("green")
      expect(helper.stat_color_class("W")).to include("amber")
      expect(helper.stat_color_class("B")).to include("gray-800")
    end

    it "returns default class for unknown colors" do
      expect(helper.stat_color_class("X")).to include("gray")
    end
  end

  describe "#stat_color_name" do
    it "returns full color name" do
      expect(helper.stat_color_name("W")).to eq("White")
      expect(helper.stat_color_name("U")).to eq("Blue")
      expect(helper.stat_color_name("B")).to eq("Black")
      expect(helper.stat_color_name("R")).to eq("Red")
      expect(helper.stat_color_name("G")).to eq("Green")
    end

    it "returns special names for special colors" do
      expect(helper.stat_color_name("Colorless")).to eq("Colorless")
      expect(helper.stat_color_name("Multicolor")).to eq("Multicolor")
    end

    it "returns code for unknown colors" do
      expect(helper.stat_color_name("X")).to eq("X")
    end
  end

  describe "#stat_percentage" do
    it "calculates percentage" do
      expect(helper.stat_percentage(25, 100)).to eq(25.0)
      expect(helper.stat_percentage(1, 3)).to eq(33.3)
    end

    it "handles zero total" do
      expect(helper.stat_percentage(5, 0)).to eq(0)
    end

    it "rounds to one decimal place" do
      expect(helper.stat_percentage(1, 7)).to eq(14.3)
    end
  end

  describe "#stat_format_percentage" do
    it "returns formatted percentage string" do
      expect(helper.stat_format_percentage(25, 100)).to eq("25.0%")
    end

    it "handles zero" do
      expect(helper.stat_format_percentage(0, 100)).to eq("0.0%")
    end
  end

  describe "#stat_rarity_class" do
    it "returns correct class for rarities" do
      expect(helper.stat_rarity_class("Common")).to include("gray-600")
      expect(helper.stat_rarity_class("Uncommon")).to include("gray-400")
      expect(helper.stat_rarity_class("Rare")).to include("amber")
      expect(helper.stat_rarity_class("Mythic")).to include("orange")
    end

    it "returns default for unknown rarity" do
      expect(helper.stat_rarity_class("Unknown")).to include("gray-300")
    end
  end

  describe "#stat_condition_bar_class" do
    it "returns correct class for conditions" do
      expect(helper.stat_condition_bar_class("near_mint")).to include("green")
      expect(helper.stat_condition_bar_class("lightly_played")).to include("lime")
      expect(helper.stat_condition_bar_class("moderately_played")).to include("yellow")
      expect(helper.stat_condition_bar_class("heavily_played")).to include("orange")
      expect(helper.stat_condition_bar_class("damaged")).to include("red")
    end
  end

  describe "#stat_color_code" do
    it "returns single letter for standard colors" do
      expect(helper.stat_color_code("W")).to eq("W")
      expect(helper.stat_color_code("U")).to eq("U")
    end

    it "returns C for Colorless" do
      expect(helper.stat_color_code("Colorless")).to eq("C")
    end

    it "returns M for Multicolor" do
      expect(helper.stat_color_code("Multicolor")).to eq("M")
    end
  end
end
