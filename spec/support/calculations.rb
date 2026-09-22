RSpec.configure do |config|
  config.before(:each, type: :request) do
    # Stub Calculation.calculatables to return an empty array for the navigation menu
    allow(Calculation).to receive(:calculatables).and_return([])
  end

  # System specs render the navigation in a real browser, so the calculation
  # rows it links to have to exist. Calculation.calculatables only creates them
  # on its first call and memoizes afterwards, which outlives the transaction
  # they were created in - hence the reset.
  config.before(:each, type: :system) do
    Calculation.remove_instance_variable(:@calculatables) if Calculation.instance_variable_defined?(:@calculatables)
    Calculation.calculatables
  end
end
