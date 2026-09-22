# frozen_string_literal: true

# Fails a system spec when the browser logged a JavaScript error.
#
# A bundle that blows up while loading (a jQuery plugin that no longer fits its
# jQuery version, for instance) still renders the page, so without this the
# markup assertions alone would pass.
module JavascriptErrors
  IGNORED_MESSAGES = [
    %r{/favicon\.ico}
  ].freeze

  def javascript_errors
    page.driver.browser.logs.get(:browser)
        .select { |entry| entry.level == 'SEVERE' }
        .map(&:message)
        .reject { |message| IGNORED_MESSAGES.any? { |ignored| message.match?(ignored) } }
  end
end

RSpec.configure do |config|
  config.include JavascriptErrors, type: :system

  config.after(:each, type: :system) do |example|
    next if example.exception

    errors = javascript_errors
    raise "JavaScript errors in the browser console:\n#{errors.join("\n")}" if errors.any?
  end
end
