require "rails_helper"

RSpec.describe ItemsHelper, type: :helper do
  describe "#language_options" do
    it "returns an array of language options" do
      options = helper.language_options
      expect(options).to be_an(Array)
      expect(options).to include([ "English", "en" ])
      expect(options).to include([ "Japanese", "ja" ])
    end
  end

  describe "#language_name" do
    it "returns English for en" do
      expect(helper.language_name("en")).to eq("English")
    end

    it "returns Japanese for ja" do
      expect(helper.language_name("ja")).to eq("Japanese")
    end

    it "returns uppercase code for unknown language" do
      expect(helper.language_name("xx")).to eq("XX")
    end
  end

  describe "#condition_options" do
    it "returns an array of condition options" do
      options = helper.condition_options
      expect(options).to be_an(Array)
      expect(options.map(&:last)).to include("near_mint", "lightly_played")
    end

    it "includes display names with abbreviations" do
      options = helper.condition_options
      expect(options.map(&:first)).to include("Near mint (NM)")
      expect(options.map(&:first)).to include("Lightly played (LP)")
    end
  end

  describe "#condition_display_name" do
    it "returns humanized name with abbreviation" do
      expect(helper.condition_display_name("near_mint")).to eq("Near mint (NM)")
      expect(helper.condition_display_name("lightly_played")).to eq("Lightly played (LP)")
    end
  end

  describe "#condition_abbreviation" do
    it "returns NM for near_mint" do
      expect(helper.condition_abbreviation("near_mint")).to eq("NM")
    end

    it "returns LP for lightly_played" do
      expect(helper.condition_abbreviation("lightly_played")).to eq("LP")
    end

    it "returns MP for moderately_played" do
      expect(helper.condition_abbreviation("moderately_played")).to eq("MP")
    end

    it "returns HP for heavily_played" do
      expect(helper.condition_abbreviation("heavily_played")).to eq("HP")
    end

    it "returns D for damaged" do
      expect(helper.condition_abbreviation("damaged")).to eq("D")
    end
  end

  describe "#condition_badge_class" do
    it "returns green for near_mint" do
      expect(helper.condition_badge_class("near_mint")).to include("green")
    end

    it "returns yellow for lightly_played" do
      expect(helper.condition_badge_class("lightly_played")).to include("yellow")
    end

    it "returns orange for moderately_played" do
      expect(helper.condition_badge_class("moderately_played")).to include("orange")
    end

    it "returns red for heavily_played" do
      expect(helper.condition_badge_class("heavily_played")).to include("red")
    end

    it "returns gray for damaged" do
      expect(helper.condition_badge_class("damaged")).to include("gray")
    end
  end

  describe "#finish_options" do
    it "returns an array of finish options" do
      options = helper.finish_options
      expect(options).to be_an(Array)
      expect(options.map(&:last)).to include("nonfoil", "traditional_foil")
    end

    it "humanizes finish names" do
      options = helper.finish_options
      expect(options.map(&:first)).to include("Nonfoil")
      expect(options.map(&:first)).to include("Traditional Foil")
    end
  end

  describe "#finish_badge_class" do
    it "returns gradient for traditional_foil" do
      expect(helper.finish_badge_class("traditional_foil")).to include("gradient")
    end

    it "returns gradient for etched" do
      expect(helper.finish_badge_class("etched")).to include("gradient")
    end

    it "returns blue for glossy" do
      expect(helper.finish_badge_class("glossy")).to include("blue")
    end

    it "returns empty string for nonfoil" do
      expect(helper.finish_badge_class("nonfoil")).to eq("")
    end
  end

  describe "#foil?" do
    it "returns true for traditional_foil" do
      item = build(:item, finish: :traditional_foil)
      expect(helper.foil?(item)).to be true
    end

    it "returns true for etched" do
      item = build(:item, finish: :etched)
      expect(helper.foil?(item)).to be true
    end

    it "returns true for surge_foil" do
      item = build(:item, finish: :surge_foil)
      expect(helper.foil?(item)).to be true
    end

    it "returns false for nonfoil" do
      item = build(:item, finish: :nonfoil)
      expect(helper.foil?(item)).to be false
    end
  end

  describe "#special_attributes" do
    it "returns Signed when signed" do
      item = build(:item, signed: true)
      expect(helper.special_attributes(item)).to include("Signed")
    end

    it "returns Altered when altered" do
      item = build(:item, altered: true)
      expect(helper.special_attributes(item)).to include("Altered")
    end

    it "returns Misprint when misprint" do
      item = build(:item, misprint: true)
      expect(helper.special_attributes(item)).to include("Misprint")
    end

    it "returns multiple attributes" do
      item = build(:item, signed: true, altered: true, misprint: true)
      attrs = helper.special_attributes(item)
      expect(attrs).to eq([ "Signed", "Altered", "Misprint" ])
    end

    it "returns empty array when no special attributes" do
      item = build(:item, signed: false, altered: false, misprint: false)
      expect(helper.special_attributes(item)).to be_empty
    end
  end

  describe "#color_options" do
    it "returns an array of color options" do
      options = helper.color_options
      expect(options).to be_an(Array)
      expect(options.first).to eq([ "All Colors", "" ])
    end

    it "includes all MTG colors" do
      options = helper.color_options
      expect(options).to include([ "White", "W" ])
      expect(options).to include([ "Blue", "U" ])
      expect(options).to include([ "Black", "B" ])
      expect(options).to include([ "Red", "R" ])
      expect(options).to include([ "Green", "G" ])
    end

    it "includes colorless and multicolor" do
      options = helper.color_options
      expect(options).to include([ "Colorless", "C" ])
      expect(options).to include([ "Multicolor", "M" ])
    end
  end

  describe "#type_options" do
    it "returns an array of type options" do
      options = helper.type_options
      expect(options).to be_an(Array)
      expect(options.first).to eq([ "All Types", "" ])
    end

    it "includes major card types" do
      options = helper.type_options
      expect(options).to include([ "Creature", "Creature" ])
      expect(options).to include([ "Instant", "Instant" ])
      expect(options).to include([ "Sorcery", "Sorcery" ])
      expect(options).to include([ "Land", "Land" ])
    end
  end

  describe "#finish_filter_options" do
    it "returns an array of finish filter options" do
      options = helper.finish_filter_options
      expect(options).to be_an(Array)
      expect(options.first).to eq([ "All Finishes", "" ])
    end

    it "includes foil aggregate option" do
      options = helper.finish_filter_options
      expect(options).to include([ "Any Foil", "foil" ])
    end
  end

  describe "#sort_options" do
    it "returns an array of sort options" do
      options = helper.sort_options
      expect(options).to be_an(Array)
    end

    it "includes date and name options" do
      options = helper.sort_options
      expect(options).to include([ "Newest First", "date_desc" ])
      expect(options).to include([ "Name (A-Z)", "name_asc" ])
    end
  end

  describe "#condition_filter_options" do
    it "starts with All Conditions" do
      options = helper.condition_filter_options
      expect(options.first).to eq([ "All Conditions", "" ])
    end

    it "includes all condition options" do
      options = helper.condition_filter_options
      expect(options.map(&:last)).to include("near_mint", "lightly_played")
    end
  end

  describe "#color_symbol" do
    it "returns full name for color codes" do
      expect(helper.color_symbol("W")).to eq("White")
      expect(helper.color_symbol("U")).to eq("Blue")
      expect(helper.color_symbol("B")).to eq("Black")
      expect(helper.color_symbol("R")).to eq("Red")
      expect(helper.color_symbol("G")).to eq("Green")
    end

    it "returns Colorless for C" do
      expect(helper.color_symbol("C")).to eq("Colorless")
    end

    it "returns Multicolor for M" do
      expect(helper.color_symbol("M")).to eq("Multicolor")
    end

    it "returns the code itself for unknown codes" do
      expect(helper.color_symbol("X")).to eq("X")
    end
  end

  describe "#set_filter_options" do
    it "starts with All Sets" do
      options = helper.set_filter_options(%w[MH3 ONE BRO])
      expect(options.first).to eq([ "All Sets", "" ])
    end

    it "includes provided sets" do
      options = helper.set_filter_options(%w[MH3 ONE])
      expect(options).to include([ "MH3", "MH3" ])
      expect(options).to include([ "ONE", "ONE" ])
    end
  end
end
