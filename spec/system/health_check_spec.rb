require "system_helper"

RSpec.describe "Rails Health Check", type: :system do
  scenario "returns green page" do
    visit rails_health_check_path

    expect(page).to have_css('body[style*="background-color: green"]')
  end
end
