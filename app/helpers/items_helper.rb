module ItemsHelper
  COLOR_OPTIONS = [
    [ "All Colors", "" ],
    [ "White", "W" ],
    [ "Blue", "U" ],
    [ "Black", "B" ],
    [ "Red", "R" ],
    [ "Green", "G" ],
    [ "Colorless", "C" ],
    [ "Multicolor", "M" ]
  ].freeze

  TYPE_OPTIONS = [
    [ "All Types", "" ],
    [ "Creature", "Creature" ],
    [ "Instant", "Instant" ],
    [ "Sorcery", "Sorcery" ],
    [ "Artifact", "Artifact" ],
    [ "Enchantment", "Enchantment" ],
    [ "Planeswalker", "Planeswalker" ],
    [ "Land", "Land" ]
  ].freeze

  FINISH_FILTER_OPTIONS = [
    [ "All Finishes", "" ],
    [ "Non-foil", "nonfoil" ],
    [ "Any Foil", "foil" ],
    [ "Traditional Foil", "traditional_foil" ],
    [ "Etched", "etched" ]
  ].freeze

  SORT_OPTIONS = [
    [ "Newest First", "date_desc" ],
    [ "Oldest First", "date_asc" ],
    [ "Name (A-Z)", "name_asc" ],
    [ "Name (Z-A)", "name_desc" ],
    [ "Condition (Best)", "condition_asc" ],
    [ "Condition (Worst)", "condition_desc" ]
  ].freeze

  LANGUAGES = [
    [ "English", "en" ],
    [ "Japanese", "ja" ],
    [ "German", "de" ],
    [ "French", "fr" ],
    [ "Italian", "it" ],
    [ "Spanish", "es" ],
    [ "Portuguese", "pt" ],
    [ "Korean", "ko" ],
    [ "Russian", "ru" ],
    [ "Chinese (Simplified)", "zhs" ],
    [ "Chinese (Traditional)", "zht" ],
    [ "Phyrexian", "ph" ],
    [ "Arabic", "ar" ],
    [ "Hebrew", "he" ],
    [ "Latin", "la" ],
    [ "Ancient Greek", "grc" ],
    [ "Sanskrit", "sa" ]
  ].freeze

  CONDITION_ABBREVIATIONS = {
    "near_mint" => "NM",
    "lightly_played" => "LP",
    "moderately_played" => "MP",
    "heavily_played" => "HP",
    "damaged" => "D"
  }.freeze

  def language_options
    LANGUAGES
  end

  def language_name(code)
    LANGUAGES.find { |_, c| c == code }&.first || code.upcase
  end

  def condition_options
    Item.conditions.keys.map do |c|
      [ condition_display_name(c), c ]
    end
  end

  def condition_display_name(condition)
    "#{condition.humanize} (#{CONDITION_ABBREVIATIONS[condition]})"
  end

  def condition_abbreviation(condition)
    CONDITION_ABBREVIATIONS[condition] || condition.upcase
  end

  def condition_badge_class(condition)
    case condition
    when "near_mint" then "bg-green-100 text-green-800"
    when "lightly_played" then "bg-yellow-100 text-yellow-800"
    when "moderately_played" then "bg-orange-100 text-orange-800"
    when "heavily_played" then "bg-red-100 text-red-800"
    when "damaged" then "bg-gray-100 text-gray-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  def finish_options
    Item.finishes.keys.map do |f|
      [ f.humanize.titleize, f ]
    end
  end

  def finish_badge_class(finish)
    case finish
    when "traditional_foil", "etched", "textured", "surge_foil"
      "bg-gradient-to-r from-purple-400 to-pink-400 text-white"
    when "glossy"
      "bg-blue-100 text-blue-800"
    else
      "" # No special styling for non-foil
    end
  end

  def foil?(item)
    %w[traditional_foil etched textured surge_foil glossy].include?(item.finish)
  end

  def special_attributes(item)
    attrs = []
    attrs << "Signed" if item.signed
    attrs << "Altered" if item.altered
    attrs << "Misprint" if item.misprint
    attrs
  end

  def color_options
    COLOR_OPTIONS
  end

  def type_options
    TYPE_OPTIONS
  end

  def finish_filter_options
    FINISH_FILTER_OPTIONS
  end

  def sort_options
    SORT_OPTIONS
  end

  def condition_filter_options
    [ [ "All Conditions", "" ] ] + condition_options
  end

  def color_symbol(color_code)
    {
      "W" => "White",
      "U" => "Blue",
      "B" => "Black",
      "R" => "Red",
      "G" => "Green",
      "C" => "Colorless",
      "M" => "Multicolor"
    }[color_code] || color_code
  end

  def set_filter_options(available_sets)
    [ [ "All Sets", "" ] ] + available_sets.map { |s| [ s, s ] }
  end
end
