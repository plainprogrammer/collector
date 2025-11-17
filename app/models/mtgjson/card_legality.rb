module MTGJSON
  class CardLegality < Base
    self.table_name = "cardLegalities"
    self.primary_key = nil
    self.implicit_order_column = "uuid"

    belongs_to :card, foreign_key: "uuid", primary_key: "uuid"

    # Note: Legality data is stored as columns (alchemy, brawl, commander, etc.)
    # Each column contains values like "Legal", "Banned", "Restricted", etc.
    # Example: CardLegality.where("commander = ?", "Legal")
  end
end
