class CreateApiStafferTokens < ActiveRecord::Migration
  def change
    create_table :api_staffer_tokens do |t|
      t.string :access_token, null:false
      t.datetime :expires_at
      t.references :staffer, null:false
      t.boolean :active, null: false, default: true
      t.string :sn_code

      t.timestamps null: false
    end
  end
end
