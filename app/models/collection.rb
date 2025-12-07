class Collection < ApplicationRecord
  has_many :storage_units, dependent: :destroy
  has_many :items, dependent: :destroy

  validates :name, presence: true

  def loose_items
    items.where(storage_unit_id: nil)
  end

  def loose_items_count
    loose_items.count
  end
end
