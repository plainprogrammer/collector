# frozen_string_literal: true

require "capybara/rspec"
require "capybara/cuprite"

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :cuprite

Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [ 1400, 900 ],
    browser_options: {
      "no-sandbox" => nil,
      "disable-gpu" => nil
    },
    process_timeout: 15,
    timeout: 10,
    inspector: ENV["INSPECTOR"]
  )
end
