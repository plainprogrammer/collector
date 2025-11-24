class StorageUnit < ApplicationRecord
  belongs_to :collection
  belongs_to :parent, class_name: "StorageUnit", optional: true
  has_many :children, class_name: "StorageUnit", foreign_key: :parent_id, dependent: :destroy
  has_many :items, dependent: :nullify

  enum :storage_unit_type, {
    box: 0,
    binder: 1,
    deck: 2,
    deck_box: 3,
    portfolio: 4,
    toploader_case: 5,
    loose: 6,
    other: 99
  }

  validates :name, presence: true
  validates :storage_unit_type, presence: true
  validates :collection_id, presence: true
  validate :prevent_circular_nesting

  private

  def prevent_circular_nesting
    return unless parent_id

    # Check if parent_id points to self
    if parent_id == id
      errors.add(:parent_id, "cannot be the same as the storage unit itself")
      return
    end

    # Check for circular reference by traversing up the parent chain
    current = parent
    visited = Set.new
    while current
      if current.id == id
        errors.add(:parent_id, "creates a circular reference")
        break
      end

      # Prevent infinite loop if there's an existing circular reference
      if visited.include?(current.id)
        break
      end
      visited.add(current.id)

      current = current.parent
    end
  end
end
