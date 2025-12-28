# frozen_string_literal: true

namespace :catalog do
  desc "Initialize default MTGJSON catalog"
  task initialize: :environment do
    # Check if MTGJSON catalog already exists
    existing_catalog = Catalog.find_by(source_type: "mtgjson")

    if existing_catalog
      puts "MTGJSON catalog already exists (ID: #{existing_catalog.id})"
      puts "MTGJSON catalog initialized successfully"
    else
      catalog = Catalog.create!(
        name: "MTGJSON Catalog",
        source_type: "mtgjson",
        source_config: {
          version: "5.2.2",  # Will be updated with actual version during import
          url: "https://mtgjson.com"
        }
      )

      puts "Created MTGJSON catalog (ID: #{catalog.id})"
      puts "MTGJSON catalog initialized successfully"
    end
  end
end
