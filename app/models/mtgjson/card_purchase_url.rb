module MTGJSON
  class CardPurchaseUrl < Base
    self.table_name = "cardPurchaseUrls"
    belongs_to :card, foreign_key: "uuid", primary_key: "uuid"
  end
end
