module MTGJSON
  class CardLegality < Base
    self.table_name = "cardLegalities"
    belongs_to :card, foreign_key: "uuid", primary_key: "uuid"

    scope :legal_in, ->(format) { where(format: format, status: "Legal") }
  end
end
