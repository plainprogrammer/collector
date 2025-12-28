# frozen_string_literal: true

module MTGJSON
  # Service to track MTGJSON version and import metadata in Catalog.source_config.
  #
  # Enables incremental updates by storing:
  # - version: MTGJSON version string
  # - last_updated: timestamp of last import
  # - import_stats: statistics from last import (sets, cards, duration)
  #
  # Usage:
  #   tracker = MTGJSON::MetaTracker.new(catalog)
  #   tracker.current_version # => "5.2.2" or nil
  #   tracker.needs_update?("5.3.0") # => true
  #   tracker.update_version("5.3.0")
  #   tracker.record_import_stats(sets_imported: 100, cards_imported: 80000)
  class MetaTracker
    attr_reader :catalog

    def initialize(catalog)
      @catalog = catalog
    end

    # Returns the currently stored MTGJSON version.
    #
    # @return [String, nil] Version string or nil if not set
    def current_version
      catalog.source_config["version"]
    end

    # Updates the stored MTGJSON version and timestamp.
    #
    # @param version [String] MTGJSON version string
    # @return [Boolean] true if update successful
    def update_version(version)
      updated_config = catalog.source_config.merge(
        "version" => version,
        "last_updated" => Time.current.iso8601
      )

      catalog.update!(source_config: updated_config)
    end

    # Checks if an update is needed based on version comparison.
    #
    # @param new_version [String] MTGJSON version to compare against
    # @return [Boolean] true if update needed (no version or version differs)
    def needs_update?(new_version)
      current_version.nil? || current_version != new_version
    end

    # Returns stored import statistics.
    #
    # @return [Hash] Import statistics hash (empty if not set)
    def import_stats
      catalog.source_config["import_stats"] || {}
    end

    # Records import statistics in catalog source_config.
    #
    # @param stats [Hash] Import statistics (sets_imported, cards_imported, import_duration, etc.)
    # @return [Boolean] true if update successful
    def record_import_stats(stats)
      updated_config = catalog.source_config.merge(
        "import_stats" => stats.stringify_keys
      )

      catalog.update!(source_config: updated_config)
    end
  end
end
