class AddNrToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :nr, :integer
    add_index :articles, :nr, unique: true
  end
end
