class Item < ApplicationRecord
  belongs_to :collection
  belongs_to :storage_unit, optional: true

  enum :finish, {
    nonfoil: 0,
    traditional_foil: 1,
    etched: 2,
    glossy: 3,
    textured: 4,
    surge_foil: 5
  }

  enum :condition, {
    near_mint: 0,
    lightly_played: 1,
    moderately_played: 2,
    heavily_played: 3,
    damaged: 4
  }

  validates :collection_id, presence: true
  validates :card_uuid, presence: true
  validates :finish, presence: true
  validates :condition, presence: true
  validates :language, presence: true, length: { is: 2 }
  validates :grading_score, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 10.0 }, allow_nil: true
  validate :storage_unit_belongs_to_collection

  # Method to access MTGJSON card data
  def card
    @card ||= MTGJSON::Card.find_by(uuid: card_uuid)
  end

  # Move item to a different collection, clearing storage unit if needed
  def move_to_collection!(new_collection, new_storage_unit: nil)
    transaction do
      self.collection = new_collection
      self.storage_unit = new_storage_unit
      save!
    end
  end

  private

  def storage_unit_belongs_to_collection
    return if storage_unit.nil?
    return if storage_unit.collection_id == collection_id

    errors.add(:storage_unit, "must belong to the same collection as the item")
  end
end
