# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupsImporter do
  let(:csv) do
    StringIO.new(<<~CSV)
      Name,interner Name,Packstraße,Budget
      Test-Kochgruppe,Hase,Packstraße 1,"1500,50"
    CSV
  end

  it 'imports budget with german decimal comma', :aggregate_failures do
    described_class.new(file: csv).run!

    group = Group.find_by!(name: 'Test-Kochgruppe')

    expect(group.internal_name).to eq('Hase')
    expect(group.budget).to eq(1500.5)
  end
end
