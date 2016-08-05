class CreateEmailTokens < ActiveRecord::Migration
  def change
    create_table :email_tokens do |t|
      t.string :email
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at

      t.timestamps null: false
    end
  end
end
