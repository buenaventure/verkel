# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Groups' do
  let(:user) { create(:user, role: :office) }
  let(:group) { create(:group) }

  before do
    sign_in user, scope: :user
  end

  describe 'GET /groups' do
    it 'returns a successful response' do
      get groups_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /groups/meals_overview' do
    it 'returns a successful response' do
      get meals_overview_groups_path
      expect(response).to have_http_status(:success)
    end

    it 'returns CSV format', :aggregate_failures do
      get meals_overview_groups_path(format: :csv)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('text/csv')
    end
  end

  describe 'GET /groups/diets_overview' do
    it 'returns a successful response' do
      get diets_overview_groups_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /groups/:id' do
    it 'returns a successful response' do
      get group_path(group)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /groups/new' do
    it 'returns a successful response' do
      get new_group_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /groups/:id/edit' do
    it 'returns a successful response' do
      get edit_group_path(group)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /groups' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          group: {
            name: 'New Group',
            internal_name: 'NG',
            hunger_factor: 1.0,
            packing_lane_id: create(:packing_lane).id
          }
        }
      end

      it 'creates a new group' do
        expect do
          post groups_path, params: valid_attributes
        end.to change(Group, :count).by(1)
      end

      it 'redirects to the created group' do
        post groups_path, params: valid_attributes
        expect(response).to redirect_to(group_path(Group.last))
      end

      it 'sets a success notice' do
        post groups_path, params: valid_attributes
        follow_redirect!
        expect(response.body).to include('erfolgreich erstellt')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          group: {
            name: ''
          }
        }
      end

      it 'does not create a new group' do
        expect do
          post groups_path, params: invalid_attributes
        end.not_to change(Group, :count)
      end

      it 'returns unprocessable_entity status' do
        post groups_path, params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'PATCH /groups/:id' do
    context 'with valid parameters' do
      let(:new_attributes) do
        {
          group: {
            name: 'Updated Group Name',
            internal_name: 'UGN'
          }
        }
      end

      it 'updates the requested group', :aggregate_failures do
        patch group_path(group), params: new_attributes
        group.reload
        expect(group.name).to eq('Updated Group Name')
        expect(group.internal_name).to eq('UGN')
      end

      it 'redirects to the group' do
        patch group_path(group), params: new_attributes
        expect(response).to redirect_to(group_path(group))
      end

      it 'sets a success notice' do
        patch group_path(group), params: new_attributes
        follow_redirect!
        expect(response.body).to include('erfolgreich aktualisiert')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          group: {
            name: ''
          }
        }
      end

      it 'does not update the group' do
        original_name = group.name
        patch group_path(group), params: invalid_attributes
        group.reload
        expect(group.name).to eq(original_name)
      end

      it 'returns unprocessable_entity status' do
        patch group_path(group), params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /groups/:id' do
    context 'when group can be destroyed' do
      it 'destroys the requested group' do
        group_to_delete = create(:group)
        expect do
          delete group_path(group_to_delete)
        end.to change(Group, :count).by(-1)
      end

      it 'redirects to the groups list' do
        group_to_delete = create(:group)
        delete group_path(group_to_delete)
        expect(response).to redirect_to(groups_path)
      end

      it 'sets a success notice' do
        group_to_delete = create(:group)
        delete group_path(group_to_delete)
        follow_redirect!
        expect(response.body).to include('erfolgreich gelöscht')
      end
    end

    context 'when group cannot be destroyed' do
      # This would happen if the group has dependent records that prevent deletion
      # For example, if it has participants with restrict_with_error
      # We'll create a scenario that could cause a destroy failure
      it 'handles destroy failure gracefully' do
        create(:participant, group:)
        delete group_path(group)
        expect(response).to redirect_to(group_path(group))
      end
    end
  end
end
