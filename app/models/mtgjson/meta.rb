module MTGJSON
  class Meta < Base
    self.table_name = "meta"

    # Utility method to get current database version
    def self.current_version
      first&.version || "unknown"
    end

    def self.last_updated
      first&.date || "unknown"
    end
  end
end
