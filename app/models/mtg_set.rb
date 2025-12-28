# frozen_string_literal: true

# MTGSet model represents a Magic: The Gathering set/expansion.
# Contains metadata about the set imported from MTGJSON.
#
# Attributes:
# - id (UUID): Primary key
# - code: Set code (e.g., "MH3", "LEB")
# - name: Full set name (e.g., "Modern Horizons 3")
# - release_date: Official release date
# - set_type: Type (expansion, core, masters, etc.)
# - card_count: Total cards in set
# - icon_uri: Set symbol image URL
class MTGSet < ApplicationRecord
  # Associations
  has_many :mtg_cards, dependent: :destroy

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  # Callbacks
  before_validation :generate_uuid, on: :create

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
