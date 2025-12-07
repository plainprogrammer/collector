class ItemFilters
  COLORS = %w[W U B R G].freeze
  TYPES = %w[Creature Instant Sorcery Artifact Enchantment Planeswalker Land].freeze
  FOIL_FINISHES = %w[traditional_foil etched glossy textured surge_foil].freeze

  attr_reader :set, :color, :type, :condition, :finish

  def initialize(params)
    @set = params[:set].presence
    @color = params[:color].presence
    @type = params[:type].presence
    @condition = params[:condition].presence
    @finish = params[:finish].presence
  end

  def apply(items, cards:)
    return items if empty?

    # Filter by item attributes (can be done in SQL)
    items = items.where(condition: condition) if condition.present?
    items = apply_finish_filter(items) if finish.present?

    # Filter by card attributes (requires card lookup)
    if set.present? || color.present? || type.present?
      matching_uuids = filter_card_uuids(cards)
      items = items.where(card_uuid: matching_uuids)
    end

    items
  end

  def empty?
    [ set, color, type, condition, finish ].all?(&:blank?)
  end

  def to_h
    {
      set: set,
      color: color,
      type: type,
      condition: condition,
      finish: finish
    }.compact
  end

  def active_count
    to_h.size
  end

  private

  def apply_finish_filter(items)
    case finish
    when "foil"
      items.where(finish: FOIL_FINISHES)
    when "nonfoil"
      items.where(finish: "nonfoil")
    else
      items.where(finish: finish)
    end
  end

  def filter_card_uuids(cards)
    cards.values.select do |card|
      matches_set?(card) && matches_color?(card) && matches_type?(card)
    end.map(&:uuid)
  end

  def matches_set?(card)
    return true if set.blank?
    card.setCode == set
  end

  def matches_color?(card)
    return true if color.blank?

    card_colors = parse_colors(card.colors)

    case color
    when "C"
      card_colors.empty?
    when "M"
      card_colors.size > 1
    else
      card_colors.include?(color)
    end
  end

  def matches_type?(card)
    return true if type.blank?
    card.type&.include?(type)
  end

  def parse_colors(colors_string)
    return [] if colors_string.blank?
    JSON.parse(colors_string)
  rescue JSON::ParserError
    []
  end
end
