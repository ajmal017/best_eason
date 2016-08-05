class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.integer :user_id
      t.integer :contest_id
      t.string :original_money
      t.integer :status
      t.integer :trading_account_id

      t.timestamps null: false
    end
  end
end
