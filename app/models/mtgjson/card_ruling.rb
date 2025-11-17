module MTGJSON
  class CardRuling < Base
    self.table_name = "cardRulings"
    belongs_to :card, foreign_key: "uuid", primary_key: "uuid"
  end
end
