# frozen_string_literal: true

# Adapter for MTGJSON data source.
# Provides access to Magic: The Gathering card catalog from MTGJSON.
#
# Phase 0.3: Simplified implementation with basic interface methods.
# Full bulk import from MTGJSON will be added in future iterations.
class MTGJSONAdapter < CatalogAdapter
  # Search for MTG cards matching the given query.
  #
  # @param query [String] The search query
  # @param options [Hash] Additional search options (limit, offset)
  # @return [ActiveRecord::Relation] Collection of MTGCard entries matching the query
  def search(query, options = {})
    results = MTGCard.search(query)
    results = results.limit(options[:limit]) if options[:limit]
    results = results.offset(options[:offset]) if options[:offset]
    results
  end

  # Fetch a specific MTG card by its UUID.
  #
  # @param identifier [String] The MTGJSON UUID for the card
  # @return [MTGCard, nil] The card entry or nil if not found
  def fetch_entry(identifier)
    MTGCard.find_by_uuid(identifier)
  end

  # Refresh a card entry with updated data from MTGJSON.
  # Phase 0.3: Placeholder - returns the entry unchanged
  #
  # @param entry [MTGCard] The card entry to refresh
  # @return [MTGCard] The entry (unchanged in Phase 0.3)
  def refresh(entry)
    # Full implementation would fetch latest data from MTGJSON and update
    # For now, just return the entry as-is
    entry
  end

  # Perform a bulk import of MTGJSON data.
  # Phase 0.3: Simplified placeholder implementation
  #
  # @param options [Hash] Import options (source_path, limit for testing)
  # @return [Hash] Import statistics
  def bulk_import(options = {})
    # Full implementation would:
    # 1. Download/open MTGJSON AllPrintings.sqlite
    # 2. Parse set and card data
    # 3. Bulk insert into MTGSet and MTGCard tables
    # 4. Update catalog version metadata
    #
    # Phase 0.3: Return stub statistics
    {
      success: true,
      sets_imported: 0,
      cards_imported: 0,
      duration: 0.0,
      message: "Bulk import placeholder - full implementation in future phase"
    }
  end
end
