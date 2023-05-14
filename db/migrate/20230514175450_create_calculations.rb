class CreateCalculations < ActiveRecord::Migration[7.0]
  def change
    create_table :calculations, id: :string do |t|
      t.integer :count
      t.timestamps
    end
  end
end
