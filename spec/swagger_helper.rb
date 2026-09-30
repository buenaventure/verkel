# frozen_string_literal: true

require 'rails_helper'

# Schemas close every object with additionalProperties: false, so a field added to a
# template without being documented here fails the spec that renders it.
module ApiSchemas
  def self.object(properties)
    { type: :object, properties:, required: properties.keys, additionalProperties: false }
  end

  def self.list(key, item)
    object(key => { type: :array, items: item })
  end

  def self.nullable(schema)
    schema.merge(nullable: true)
  end

  TIMESTAMP = { type: :string, format: 'date-time' }.freeze
  NULLABLE_TIMESTAMP = { type: :string, format: 'date-time', nullable: true }.freeze
  NUMBER = { type: :number }.freeze
  NULLABLE_NUMBER = { type: :number, nullable: true }.freeze
  NULLABLE_STRING = { type: :string, nullable: true }.freeze
  REF = object(id: { type: :integer }, name: { type: :string })
  MEAL_REF = object(id: { type: :integer }, name: NULLABLE_STRING, datetime: NULLABLE_TIMESTAMP)

  SCHEMAS = {
    Error: object(error: { type: :string }),
    Meta: object(generated_at: TIMESTAMP),
    Ref: REF,
    MealSummary: object(
      id: { type: :integer }, name: NULLABLE_STRING, datetime: NULLABLE_TIMESTAMP,
      optional: { type: :boolean }, bundle: { type: :boolean }, estimated_share: NULLABLE_NUMBER,
      servings: { type: :integer }, recipe: REF, box_id: { type: :integer, nullable: true }
    ),
    Meal: object(
      id: { type: :integer }, name: NULLABLE_STRING, datetime: NULLABLE_TIMESTAMP,
      optional: { type: :boolean }, bundle: { type: :boolean }, estimated_share: NULLABLE_NUMBER,
      servings: { type: :integer },
      recipe: object(id: { type: :integer }, name: { type: :string }, servings: NULLABLE_NUMBER),
      box: nullable(object(id: { type: :integer }, datetime: NULLABLE_TIMESTAMP)),
      servings_per_group: { type: :array, items: object(group: REF, servings: { type: :integer }) },
      created_at: TIMESTAMP, updated_at: TIMESTAMP
    ),
    RecipeSummary: object(
      id: { type: :integer }, name: { type: :string }, servings: NULLABLE_NUMBER,
      diet_notes: NULLABLE_STRING, meals: { type: :array, items: MEAL_REF }
    ),
    Recipe: object(
      id: { type: :integer }, name: { type: :string }, servings: NULLABLE_NUMBER,
      diet_notes: NULLABLE_STRING, content: NULLABLE_STRING,
      ingredients: {
        type: :array,
        items: object(
          ingredient: REF, quantity: NULLABLE_NUMBER, unit: NULLABLE_STRING,
          positive_diets: { type: :array, items: REF }, negative_diets: { type: :array, items: REF }
        )
      },
      meals: { type: :array, items: MEAL_REF },
      created_at: TIMESTAMP, updated_at: TIMESTAMP
    ),
    ParticipantSummary: object(
      id: { type: :integer }, group: nullable(REF), age: { type: :integer },
      diets: { type: :array, items: REF }, meal_count: { type: :integer },
      created_at: TIMESTAMP, updated_at: TIMESTAMP
    ),
    Participant: object(
      id: { type: :integer }, group: nullable(REF), age: { type: :integer },
      diets: { type: :array, items: REF },
      group_changes: {
        type: :array,
        items: object(id: { type: :integer }, group: nullable(REF),
                      begins_at: NULLABLE_TIMESTAMP, ends_at: NULLABLE_TIMESTAMP)
      },
      meals: {
        type: :array,
        items: object(id: { type: :integer }, name: NULLABLE_STRING, datetime: NULLABLE_TIMESTAMP, group: REF)
      },
      created_at: TIMESTAMP, updated_at: TIMESTAMP
    )
  }.freeze

  # The { "data": …, "meta": … } envelope every JSON response comes in.
  def self.envelope(data)
    object(data:, meta: { '$ref' => '#/components/schemas/Meta' })
  end

  def self.ref(name)
    { '$ref' => "#/components/schemas/#{name}" }
  end
end

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'VerKeL API',
        version: 'v1',
        description: <<~TEXT
          Read access to VerKeL's planning data as JSON. Every endpoint is the same URL as the
          HTML page with a `.json` suffix (or `Accept: application/json`).

          Authenticate with `Authorization: Bearer <token>`; users create tokens under
          Administration → API-Tokens. A token has exactly the permissions of its user's role,
          and read tokens get 403 on anything but GET. Responses are `{ "data": …, "meta": … }`;
          errors are `{ "error": "…" }`. Each token may make 120 requests per minute.
        TEXT
      },
      paths: {},
      components: {
        securitySchemes: { bearer: { type: :http, scheme: :bearer } },
        schemas: ApiSchemas::SCHEMAS
      },
      security: [{ bearer: [] }]
    }
  }

  config.openapi_format = :yaml
end
