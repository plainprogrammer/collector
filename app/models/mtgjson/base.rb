module MTGJSON
  class Base < ApplicationRecord
    self.abstract_class = true
    connects_to database: { writing: :mtgjson, reading: :mtgjson }

    # Make all MTGJSON models read-only by default
    before_destroy :readonly!
    before_update :readonly!
    before_create :readonly!

    def readonly?
      true
    end
  end
end
