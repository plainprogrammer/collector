module CardsHelper
  SCRYFALL_IMAGE_BASE = "https://cards.scryfall.io"

  # Generate Scryfall image URL from Scryfall ID
  # Format: https://cards.scryfall.io/normal/front/a/b/abc123.jpg
  def card_image_url(card, size: :normal)
    return nil unless card.identifiers.loaded? || card.identifiers.any?

    identifier = card.identifiers.find { |i| i.scryfallId.present? }
    return nil unless identifier&.scryfallId

    scryfall_id = identifier.scryfallId
    first = scryfall_id[0]
    second = scryfall_id[1]

    "#{SCRYFALL_IMAGE_BASE}/#{size}/front/#{first}/#{second}/#{scryfall_id}.jpg"
  end

  # Generate image tag for card, with fallback to placeholder
  def card_image_tag(card, size: :normal, **options)
    url = card_image_url(card, size: size)

    if url
      image_tag url,
                alt: "#{card.name} card image",
                loading: "lazy",
                class: options[:class],
                onerror: "this.onerror=null; this.src='#{image_path('card_placeholder.svg')}'"
    else
      content_tag :div, class: "flex items-center justify-center bg-gray-100 rounded-lg #{options[:class]}" do
        content_tag :span, "Image not available", class: "text-gray-400 text-sm"
      end
    end
  end

  # Format mana cost with symbols (basic text version)
  def format_mana_cost(mana_cost)
    return "" if mana_cost.blank?

    # Simple text display: {W}{U}{B}{R}{G} → styled spans
    mana_cost.gsub(/\{([^}]+)\}/) do |_match|
      symbol = ::Regexp.last_match(1)
      content_tag(:span, symbol, class: "mana-symbol mana-#{symbol.downcase}")
    end.html_safe
  end

  # Format rarity with appropriate styling class
  def rarity_class(rarity)
    case rarity&.downcase
    when "common" then "text-gray-600"
    when "uncommon" then "text-slate-500"
    when "rare" then "text-amber-500"
    when "mythic" then "text-orange-500"
    when "special" then "text-purple-500"
    else "text-gray-600"
    end
  end

  # Format legality status with appropriate styling
  def legality_badge(status)
    case status&.downcase
    when "legal"
      content_tag :span, class: "inline-flex items-center gap-1 px-2 py-1 rounded text-xs font-medium bg-green-100 text-green-800" do
        safe_join([
          content_tag(:span, "Legal")
        ])
      end
    when "banned"
      content_tag :span, class: "inline-flex items-center gap-1 px-2 py-1 rounded text-xs font-medium bg-red-100 text-red-800" do
        safe_join([
          content_tag(:span, "Banned")
        ])
      end
    when "restricted"
      content_tag :span, class: "inline-flex items-center gap-1 px-2 py-1 rounded text-xs font-medium bg-yellow-100 text-yellow-800" do
        safe_join([
          content_tag(:span, "Restricted")
        ])
      end
    else
      content_tag :span, class: "inline-flex items-center gap-1 px-2 py-1 rounded text-xs font-medium bg-gray-100 text-gray-500" do
        safe_join([
          content_tag(:span, "Not Legal")
        ])
      end
    end
  end
end
