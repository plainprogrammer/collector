module MTGJSON
  class CardIdentifier < Base
    self.table_name = "cardIdentifiers"
    belongs_to :card, foreign_key: "uuid", primary_key: "uuid"
  end
end
