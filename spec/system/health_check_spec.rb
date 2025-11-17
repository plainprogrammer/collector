require 'rails_helper'

RSpec.describe 'Health Check', type: :system do
  it 'displays the health check page' do
    visit rails_health_check_path

    expect(page).to have_content("")
  end
end
