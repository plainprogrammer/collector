module MTGJSON
  class CardPrice < Base
    self.table_name = "cardPrices"
    belongs_to :card, foreign_key: "uuid", primary_key: "uuid"
  end
end
