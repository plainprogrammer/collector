# frozen_string_literal: true

# Base class for catalog adapters implementing the adapter pattern.
# Subclasses must implement the interface methods to provide catalog-specific functionality.
class CatalogAdapter
  attr_reader :catalog

  def initialize(catalog)
    @catalog = catalog
  end

  # Search for catalog entries matching the given query.
  #
  # @param query [String] The search query
  # @param options [Hash] Additional search options (e.g., limit, offset, filters)
  # @return [ActiveRecord::Relation] Collection of catalog entries matching the query
  # @raise [NotImplementedError] Must be implemented by subclass
  def search(query, options = {})
    raise NotImplementedError, "#{self.class} must implement #search"
  end

  # Fetch a specific catalog entry by its identifier.
  #
  # @param identifier [String] The unique identifier for the catalog entry
  # @return [Object] The catalog entry
  # @raise [NotImplementedError] Must be implemented by subclass
  def fetch_entry(identifier)
    raise NotImplementedError, "#{self.class} must implement #fetch_entry"
  end

  # Refresh a catalog entry with updated data from the source.
  #
  # @param entry [Object] The catalog entry to refresh
  # @return [Object] The refreshed catalog entry
  # @raise [NotImplementedError] Must be implemented by subclass
  def refresh(entry)
    raise NotImplementedError, "#{self.class} must implement #refresh"
  end

  # Perform a bulk import of catalog data.
  #
  # @param options [Hash] Import options (e.g., source path, batch size)
  # @return [Hash] Import statistics (e.g., imported count, failed count)
  # @raise [NotImplementedError] Must be implemented by subclass
  def bulk_import(options = {})
    raise NotImplementedError, "#{self.class} must implement #bulk_import"
  end
end
