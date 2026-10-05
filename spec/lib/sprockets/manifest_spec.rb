# frozen_string_literal: true

require 'rails_helper'

# Production boots against the manifest written by assets:precompile, which
# development and test never create. Sprockets < 4.3 parsed it with
# JSON.parse(..., create_additions: false), which json 3 rejects, so every
# production boot (db:migrate, puma) raised an ArgumentError while the rest of
# the suite stayed green.
RSpec.describe Sprockets::Manifest do
  let(:dir) { Dir.mktmpdir }

  after { FileUtils.remove_entry(dir) }

  it 'reads a precompiled manifest with the bundled json gem' do
    assets = { 'application.css' => 'application-abc.css' }
    File.write(File.join(dir, ".sprockets-manifest-#{SecureRandom.hex(16)}.json"), JSON.generate(files: {}, assets:))

    expect(described_class.new(Sprockets::Environment.new, dir).assets).to eq(assets)
  end
end
