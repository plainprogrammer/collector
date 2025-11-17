module MTGJSON
  class Card < Base
    self.table_name = "cards"
    self.primary_key = "uuid"

    # Associations
    belongs_to :set, foreign_key: "setCode", primary_key: "code", optional: true
    has_many :identifiers, foreign_key: "uuid", primary_key: "uuid", class_name: "CardIdentifier"
    has_many :legalities, foreign_key: "uuid", primary_key: "uuid", class_name: "CardLegality"
    has_many :prices, foreign_key: "uuid", primary_key: "uuid", class_name: "CardPrice"
    has_many :rulings, foreign_key: "uuid", primary_key: "uuid", class_name: "CardRuling"
    has_many :foreign_data, foreign_key: "uuid", primary_key: "uuid", class_name: "CardForeignData"
    has_many :purchase_urls, foreign_key: "uuid", primary_key: "uuid", class_name: "CardPurchaseUrl"

    # Scopes
    scope :by_name, ->(name) { where("name LIKE ?", "%#{name}%") }
    scope :by_set, ->(set_code) { where(setCode: set_code) }
    scope :by_color, ->(colors) { where("colors LIKE ?", "%#{colors}%") }
    scope :by_type, ->(type) { where("type LIKE ?", "%#{type}%") }

    # Virtual attributes for JSON fields (if stored as JSON strings)
    # MTGJSON may store arrays as JSON - adjust as needed
  end
end
