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

  # Scopes
  # Full-text search using FTS5 virtual table
  # @param query [String] Search query
  # @return [ActiveRecord::Relation] Matching cards
  scope :search, ->(query) {
    return none if query.blank?

    # Add wildcard suffix for partial matching
    # FTS5 prefix queries allow "light*" to match "lightning"
    fts_query = query.strip.split.map { |term| "#{term}*" }.join(" ")

    # Use FTS5 MATCH for full-text search
    # The FTS5 table is kept in sync via triggers
    joins("INNER JOIN mtg_cards_fts ON mtg_cards.rowid = mtg_cards_fts.rowid")
      .where("mtg_cards_fts MATCH ?", fts_query)
      .order("rank")
  }

  # Alias for search for clearer intent
  scope :search_by_name, ->(query) { search(query) }

  # Class methods for lookups
  class << self
    # Find card by MTGJSON UUID
    # @param uuid [String] MTGJSON UUID
    # @return [MTGCard, nil]
    def find_by_uuid(uuid)
      find_by(uuid: uuid)
    end

    # Find card by Scryfall ID
    # @param scryfall_id [String] Scryfall ID
    # @return [MTGCard, nil]
    def find_by_scryfall_id(scryfall_id)
      find_by(scryfall_id: scryfall_id)
    end

    # Find card by name and set code
    # @param name [String] Card name
    # @param set_code [String] Set code
    # @return [MTGCard, nil]
    def find_by_name_and_set(name, set_code)
      find_by(name: name, set_code: set_code)
    end
  end

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
