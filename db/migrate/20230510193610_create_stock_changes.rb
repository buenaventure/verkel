class CreateStockChanges < ActiveRecord::Migration[7.0]
  def change
    create_table :stock_changes do |t|
      t.references :article, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :quantity, precision: 8, scale: 0, null: false
      t.decimal :result, precision: 8, scale: 0, null: false
      t.string :reference

      t.timestamps
    end
  end
end
