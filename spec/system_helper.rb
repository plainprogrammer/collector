# spec/system_helper.rb
require "rails_helper"
require "capybara/rspec"
require "capybara/cuprite"

# Register Cuprite driver
Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1400, 900],
    headless: %w[0 false].exclude?(ENV.fetch("HEADLESS", "true")),
    slowmo: ENV.fetch("SLOWMO", 0).to_f,
    process_timeout: 30,
    timeout: 10,
    inspector: ENV.key?("INSPECTOR"),
    browser_options: ENV["CI"] ? { "no-sandbox" => nil } : {}
  )
end

Capybara.default_driver = :cuprite

# Server configuration
Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.include Capybara::DSL, type: :system

  config.before(:each, type: :system) do
    driven_by :cuprite
  end

  # Screenshot on failure
  config.after(:each, type: :system) do |example|
    if example.exception
      timestamp = Time.current.strftime("%Y%m%d-%H%M%S")
      filename = "#{example.full_description.parameterize}-#{timestamp}"
      path = Rails.root.join("tmp/screenshots/#{filename}.png")

      page.save_screenshot(path)
      puts "\n📸 Screenshot saved: #{path}"
    end
  end
end
