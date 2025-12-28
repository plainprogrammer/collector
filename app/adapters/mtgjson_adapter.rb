# frozen_string_literal: true

# Adapter for MTGJSON data source.
# Provides access to Magic: The Gathering card catalog from MTGJSON.
#
# Phase 0.2: Placeholder implementation with interface methods raising NotImplementedError.
# Phase 0.3: Full implementation with MTGJSON bulk import and search capabilities.
class MtgjsonAdapter < CatalogAdapter
  # Search for MTG cards matching the given query.
  #
  # @param query [String] The search query
  # @param options [Hash] Additional search options (e.g., limit, offset, filters)
  # @return [ActiveRecord::Relation] Collection of MTGCard entries matching the query
  # @raise [NotImplementedError] Implementation pending in Phase 0.3
  def search(query, options = {})
    raise NotImplementedError, "MtgjsonAdapter#search will be implemented in Phase 0.3"
  end

  # Fetch a specific MTG card by its UUID.
  #
  # @param identifier [String] The MTGJSON UUID for the card
  # @return [MTGCard] The card entry
  # @raise [NotImplementedError] Implementation pending in Phase 0.3
  def fetch_entry(identifier)
    raise NotImplementedError, "MtgjsonAdapter#fetch_entry will be implemented in Phase 0.3"
  end

  # Refresh a card entry with updated data from MTGJSON.
  #
  # @param entry [MTGCard] The card entry to refresh
  # @return [MTGCard] The refreshed card entry
  # @raise [NotImplementedError] Implementation pending in Phase 0.3
  def refresh(entry)
    raise NotImplementedError, "MtgjsonAdapter#refresh will be implemented in Phase 0.3"
  end

  # Perform a bulk import of MTGJSON data.
  #
  # @param options [Hash] Import options (e.g., source path, batch size)
  # @return [Hash] Import statistics (e.g., imported count, failed count)
  # @raise [NotImplementedError] Implementation pending in Phase 0.3
  def bulk_import(options = {})
    raise NotImplementedError, "MtgjsonAdapter#bulk_import will be implemented in Phase 0.3"
  end
end
