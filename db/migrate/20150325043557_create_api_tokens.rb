class CreateApiTokens < ActiveRecord::Migration
  def change
    create_table :api_tokens do |t|
      t.string :access_token, null:false
      t.datetime :expires_at
      t.references :user, null:false
      t.boolean :active, null: false, default: true

      t.timestamps null: false
    end
  end
end
