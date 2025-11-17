module MTGJSON
  class Token < Base
    self.table_name = "tokens"
    self.primary_key = "uuid"

    has_many :identifiers, foreign_key: "uuid", primary_key: "uuid", class_name: "TokenIdentifier"
  end
end
