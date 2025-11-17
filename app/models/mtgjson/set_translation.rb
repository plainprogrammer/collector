module MTGJSON
  class SetTranslation < Base
    self.table_name = "setTranslations"
    belongs_to :set, foreign_key: "setCode", primary_key: "code"
  end
end
