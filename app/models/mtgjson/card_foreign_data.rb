module MTGJSON
  class CardForeignData < Base
    self.table_name = "cardForeignData"
    belongs_to :card, foreign_key: "uuid", primary_key: "uuid"
  end
end
