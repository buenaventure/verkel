# frozen_string_literal: true

Rswag::Ui.configure do |c|
  # The UI is mounted at /api-docs behind Devise; the description itself is served by
  # OpenapiController so that API tokens can fetch it too.
  c.openapi_endpoint '/openapi.json', 'VerKeL API v1'
end
