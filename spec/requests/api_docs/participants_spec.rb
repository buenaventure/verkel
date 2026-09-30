# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Participants API' do
  include_context 'with api data'

  path '/participants.json' do
    get 'List participants' do
      tags 'Participants'
      description <<~TEXT
        All participants with Kochgruppe, age, diets and how many meals they take part in.
        Comments and identifiers from other systems are never included.
      TEXT
      produces 'application/json'

      response '200', 'participants' do
        schema ApiSchemas.envelope(ApiSchemas.list(:participants, ApiSchemas.ref(:ParticipantSummary)))
        run_test!
      end
    end
  end

  path '/participants/{id}.json' do
    parameter name: :id, in: :path, type: :integer

    get 'Show a participant' do
      tags 'Participants'
      description 'One participant with diets, group changes and the meals they eat, by Kochgruppe.'
      produces 'application/json'

      response '200', 'participant' do
        let(:id) { participant.id }
        schema ApiSchemas.envelope(ApiSchemas.object(participant: ApiSchemas.ref(:Participant)))
        run_test!
      end
    end
  end
end
