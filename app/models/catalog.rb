# frozen_string_literal: true

class Catalog < ApplicationRecord
  # Validations
  validates :name, presence: true
  validates :source_type, presence: true, inclusion: { in: %w[mtgjson api custom] }

  # Callbacks
  before_validation :generate_uuid, on: :create

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
