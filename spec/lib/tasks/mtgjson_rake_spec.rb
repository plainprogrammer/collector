require "rails_helper"
require "rake"

RSpec.describe "mtgjson rake tasks" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before do
    # Ensure tasks can be invoked multiple times
    Rake::Task["mtgjson:info"].reenable
    Rake::Task["mtgjson:verify"].reenable
    Rake::Task["mtgjson:cleanup_backups"].reenable
  end

  describe "mtgjson:info" do
    it "displays database information when database exists" do
      db_path = Rails.root.join("storage", "mtgjson.sqlite3")

      if File.exist?(db_path)
        expect {
          Rake::Task["mtgjson:info"].invoke
        }.to output(/MTGJSON Database Information/).to_stdout
      else
        expect {
          Rake::Task["mtgjson:info"].invoke
        }.to output(/MTGJSON database not found/).to_stdout
      end
    end
  end

  describe "mtgjson:cleanup_backups" do
    it "manages backup files" do
      expect {
        Rake::Task["mtgjson:cleanup_backups"].invoke
      }.to output(/backup/).to_stdout
    end
  end

  # Note: Download/refresh tasks should not be tested in CI
  # as they require network access and download large files
  describe "mtgjson:download", skip: "Requires network and large download" do
    it "downloads the database"
  end

  describe "mtgjson:refresh", skip: "Requires network and large download" do
    it "refreshes the database"
  end
end
