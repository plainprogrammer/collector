class Collection < ApplicationRecord
  has_many :storage_units, dependent: :destroy
  has_many :items, dependent: :destroy

  validates :name, presence: true
end
