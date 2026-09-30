# frozen_string_literal: true

# json-schema 6.2 still calls JSON.parse(…, quirks_mode: true), which json 3 rejects, so
# every rswag response check would fail. Parse without the option; drop this file once
# json-schema no longer passes it.
module JsonSchemaCompat
  def parse(source)
    return super unless json_backend.to_s == 'json'

    JSON.parse(source)
  rescue JSON::ParserError => e
    raise JSON::Schema::JsonParseError, e.message
  end
end

JSON::Validator.singleton_class.prepend(JsonSchemaCompat)
