# frozen_string_literal: true

class CreateApiTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :api_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :token_digest, null: false, index: { unique: true }
      t.string :scopes, array: true, null: false, default: ['read']
      t.datetime :last_used_at
      t.datetime :expires_at
      t.datetime :revoked_at
      t.timestamps
    end
  end
end
