module MTGJSON
  class TokenIdentifier < Base
    self.table_name = "tokenIdentifiers"
    belongs_to :token, foreign_key: "uuid", primary_key: "uuid"
  end
end
