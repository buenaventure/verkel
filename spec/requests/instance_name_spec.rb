# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Instance name' do
  around do |example|
    original = Rails.application.config.instance_name
    Rails.application.config.instance_name = instance_name
    example.run
  ensure
    Rails.application.config.instance_name = original
  end

  context 'when configured' do
    let(:instance_name) { 'Sommerlager 2026' }

    it 'shows the name in the header and page title', :aggregate_failures do
      get new_user_session_path

      expect(response.body).to include('<span class="navbar-brand-instance-name">Sommerlager 2026</span>')
      expect(response.body).to match(%r{<title>.*Sommerlager 2026 – Verkel</title>})
    end
  end

  context 'when not configured' do
    let(:instance_name) { nil }

    it 'shows only the app name', :aggregate_failures do
      get new_user_session_path

      expect(response.body).not_to include('navbar-brand-instance')
      expect(response.body).to include('>VerKeL</a>')
    end
  end
end
