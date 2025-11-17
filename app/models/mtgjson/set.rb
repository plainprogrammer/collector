module MTGJSON
  class Set < Base
    self.table_name = "sets"
    self.primary_key = "code"
    self.inheritance_column = nil  # Disable STI - 'type' is a set attribute, not inheritance

    # Associations
    has_many :cards, foreign_key: "setCode", primary_key: "code"
    has_many :translations, foreign_key: "setCode", primary_key: "code", class_name: "SetTranslation"
    has_many :booster_contents, foreign_key: "setCode", primary_key: "code", class_name: "SetBoosterContent"

    # Scopes
    scope :released, -> { where("releaseDate <= ?", Date.today) }
    scope :upcoming, -> { where("releaseDate > ?", Date.today) }
    scope :by_type, ->(type) { where(type: type) }
    scope :by_year, ->(year) { where("releaseDate LIKE ?", "#{year}%") }
  end
end
