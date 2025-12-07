class CollectionStatistics
  attr_reader :collection

  def initialize(collection)
    @collection = collection
    @items = collection.items
    @cards_cache = nil
  end

  def total_count
    @total_count ||= @items.count
  end

  def unique_count
    @unique_count ||= @items.distinct.count(:card_uuid)
  end

  def average_copies
    return 0 if unique_count.zero?
    (total_count.to_f / unique_count).round(2)
  end

  def set_breakdown
    @set_breakdown ||= calculate_set_breakdown
  end

  def color_breakdown
    @color_breakdown ||= calculate_color_breakdown
  end

  def type_breakdown
    @type_breakdown ||= calculate_type_breakdown
  end

  def condition_breakdown
    @condition_breakdown ||= @items.group(:condition).count.transform_keys { |k| Item.conditions.key(k) || k }
  end

  def finish_breakdown
    @finish_breakdown ||= @items.group(:finish).count.transform_keys { |k| Item.finishes.key(k) || k }
  end

  def rarity_breakdown
    @rarity_breakdown ||= calculate_rarity_breakdown
  end

  def foil_count
    @foil_count ||= @items.where.not(finish: :nonfoil).count
  end

  def foil_percentage
    return 0 if total_count.zero?
    ((foil_count.to_f / total_count) * 100).round(1)
  end

  private

  def cards
    @cards_cache ||= load_cards
  end

  def load_cards
    uuids = @items.pluck(:card_uuid).uniq
    MTGJSON::Card.where(uuid: uuids).index_by(&:uuid)
  end

  def calculate_set_breakdown
    uuid_counts = @items.group(:card_uuid).count

    set_counts = Hash.new(0)
    uuid_counts.each do |uuid, count|
      card = cards[uuid]
      next unless card
      set_counts[card.setCode] += count
    end

    set_counts.sort_by { |_, count| -count }.to_h
  end

  def calculate_color_breakdown
    color_counts = {
      "W" => 0, "U" => 0, "B" => 0, "R" => 0, "G" => 0,
      "Colorless" => 0, "Multicolor" => 0
    }

    uuid_counts = @items.group(:card_uuid).count
    uuid_counts.each do |uuid, count|
      card = cards[uuid]
      next unless card

      card_colors = parse_colors(card.colors)

      if card_colors.empty?
        color_counts["Colorless"] += count
      elsif card_colors.size > 1
        color_counts["Multicolor"] += count
      else
        color_counts[card_colors.first] += count if color_counts.key?(card_colors.first)
      end
    end

    color_counts
  end

  def calculate_type_breakdown
    type_counts = Hash.new(0)
    types_to_track = %w[Creature Instant Sorcery Artifact Enchantment Planeswalker Land]

    uuid_counts = @items.group(:card_uuid).count
    uuid_counts.each do |uuid, count|
      card = cards[uuid]
      next unless card

      types_to_track.each do |type|
        type_counts[type] += count if card.type&.include?(type)
      end
    end

    type_counts.sort_by { |_, count| -count }.to_h
  end

  def calculate_rarity_breakdown
    rarity_counts = Hash.new(0)

    uuid_counts = @items.group(:card_uuid).count
    uuid_counts.each do |uuid, count|
      card = cards[uuid]
      next unless card

      rarity = card.rarity&.capitalize || "Unknown"
      rarity_counts[rarity] += count
    end

    rarity_order = %w[Common Uncommon Rare Mythic Special Bonus Unknown]
    rarity_counts.sort_by { |r, _| rarity_order.index(r) || 99 }.to_h
  end

  def parse_colors(colors_string)
    return [] if colors_string.blank?
    JSON.parse(colors_string)
  rescue JSON::ParserError
    []
  end
end
