module MTGJSON
  class Meta < Base
    self.table_name = "meta"
    self.primary_key = nil  # Meta table has no primary key
    self.implicit_order_column = "date"  # Use date for default ordering

    # Utility method to get current database version
    def self.current_version
      first&.version || "unknown"
    end

    def self.last_updated
      first&.date || "unknown"
    end
  end
end
