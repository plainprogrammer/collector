# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "catalog:initialize", type: :task do
  before do
    Rake.application.rake_require "tasks/catalog"
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task["catalog:initialize"] }

  before do
    task.reenable
  end

  describe "execution" do
    it "creates a default MTGJSON catalog" do
      expect { task.invoke }.to change(Catalog, :count).by(1)

      catalog = Catalog.last
      expect(catalog.name).to eq("MTGJSON Catalog")
      expect(catalog.source_type).to eq("mtgjson")
      expect(catalog.source_config).to be_a(Hash)
    end

    it "sets source_config with version information" do
      task.invoke

      catalog = Catalog.last
      expect(catalog.source_config).to include("version")
    end

    it "is idempotent and does not create duplicates" do
      task.invoke
      first_catalog = Catalog.last

      task.reenable
      expect { task.invoke }.not_to change(Catalog, :count)

      expect(Catalog.last.id).to eq(first_catalog.id)
    end

    it "outputs success message" do
      expect { task.invoke }.to output(/MTGJSON catalog initialized/).to_stdout
    end
  end
end
