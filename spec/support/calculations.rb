RSpec.configure do |config|
  config.before(:each, type: :request) do
    # Stub Calculation.calculatables to return an empty array for the navigation menu
    allow(Calculation).to receive(:calculatables).and_return([])
  end
end
