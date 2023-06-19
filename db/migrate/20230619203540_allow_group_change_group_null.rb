class AllowGroupChangeGroupNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null(:group_changes, :group_id, true)
  end
end
