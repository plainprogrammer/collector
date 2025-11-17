module MTGJSON
  class SetBoosterContent < Base
    self.table_name = "setBoosterContents"
    belongs_to :set, foreign_key: "setCode", primary_key: "code"
  end
end
