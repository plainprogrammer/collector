module StatisticsHelper
  COLOR_CLASSES = {
    "W" => "bg-amber-100 text-amber-800 border-amber-300",
    "U" => "bg-blue-100 text-blue-800 border-blue-300",
    "B" => "bg-gray-800 text-gray-100 border-gray-600",
    "R" => "bg-red-100 text-red-800 border-red-300",
    "G" => "bg-green-100 text-green-800 border-green-300",
    "Colorless" => "bg-gray-100 text-gray-800 border-gray-300",
    "Multicolor" => "bg-gradient-to-r from-amber-100 via-blue-100 to-green-100 text-gray-800 border-gray-300"
  }.freeze

  COLOR_NAMES = {
    "W" => "White",
    "U" => "Blue",
    "B" => "Black",
    "R" => "Red",
    "G" => "Green",
    "Colorless" => "Colorless",
    "Multicolor" => "Multicolor"
  }.freeze

  RARITY_CLASSES = {
    "Common" => "bg-gray-600",
    "Uncommon" => "bg-gray-400",
    "Rare" => "bg-amber-500",
    "Mythic" => "bg-orange-500",
    "Special" => "bg-purple-500",
    "Bonus" => "bg-purple-400",
    "Unknown" => "bg-gray-300"
  }.freeze

  CONDITION_CLASSES = {
    "near_mint" => "bg-green-500",
    "lightly_played" => "bg-lime-500",
    "moderately_played" => "bg-yellow-500",
    "heavily_played" => "bg-orange-500",
    "damaged" => "bg-red-500"
  }.freeze

  def stat_color_class(color_code)
    COLOR_CLASSES[color_code] || "bg-gray-100 text-gray-800"
  end

  def stat_color_name(color_code)
    COLOR_NAMES[color_code] || color_code
  end

  def stat_rarity_class(rarity)
    RARITY_CLASSES[rarity] || "bg-gray-300"
  end

  def stat_condition_bar_class(condition)
    CONDITION_CLASSES[condition] || "bg-gray-300"
  end

  def stat_percentage(count, total)
    return 0 if total.zero?
    ((count.to_f / total) * 100).round(1)
  end

  def stat_format_percentage(count, total)
    "#{stat_percentage(count, total)}%"
  end

  def stat_color_code(color)
    case color
    when "Colorless" then "C"
    when "Multicolor" then "M"
    else color
    end
  end
end
