# frozen_string_literal: true

# MTGCard model represents a Magic: The Gathering card printing.
# Catalog entry type for MTG collections, implements CatalogEntryInterface.
#
# One card can have multiple printings (different sets, collector numbers).
# Each printing is a separate MTGCard record.
#
# Data imported from MTGJSON with complete card information including:
# - Identity: uuid, scryfall_id, name, set_code, collector_number
# - Display: mana_cost, type_line, oracle_text, power, toughness
# - Categorization: colors, color_identity, rarity
# - Variants: finishes (nonfoil, foil, etched), frame_effects, promo_types
# - Reference: source_data (complete MTGJSON payload)
class MTGCard < ApplicationRecord
  # Associations
  belongs_to :mtg_set
  has_many :items, as: :catalog_entry, dependent: :restrict_with_error

  # Validations
  validates :uuid, presence: true, uniqueness: true
  validates :name, presence: true
  validates :set_code, presence: true
  validates :collector_number, presence: true
  validates :scryfall_id, uniqueness: true, allow_nil: true

  # Callbacks
  before_validation :generate_uuid, on: :create

  # CatalogEntryInterface compliance
  # Returns the stable MTGJSON identifier for this card.
  #
  # @return [String] MTGJSON UUID
  def identifier
    uuid
  end

  # Returns the display name for this card.
  #
  # @return [String] Card name
  def display_name
    name
  end

  # Constructs Scryfall CDN image URL for this card.
  # Scryfall allows hotlinking from their CDN.
  #
  # @param size [Symbol] Image size (:small, :normal, :large, :png, :art_crop, :border_crop)
  # @param face [Symbol] Card face (:front, :back) for double-faced cards
  # @return [String, nil] Image URL or nil if scryfall_id not present
  def image_url(size = :normal, face: :front)
    return nil unless scryfall_id

    # Scryfall CDN URL pattern: https://cards.scryfall.io/{size}/{face}/{dir1}/{dir2}/{scryfall_id}.jpg
    dir1 = scryfall_id[0]
    dir2 = scryfall_id[1]
    "https://cards.scryfall.io/#{size}/#{face}/#{dir1}/#{dir2}/#{scryfall_id}.jpg"
  end

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
