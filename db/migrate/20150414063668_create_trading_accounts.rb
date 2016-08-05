class CreateTradingAccounts < ActiveRecord::Migration
  def change
    create_table :trading_accounts do |t|
      t.string  :broker_no
      t.integer :user_id
      t.integer :broker_id
      t.integer :status
      t.string  :confirmation_token
      t.datetime :confirmation_sent_at
      t.string :email
      t.string :password
      t.integer :count # 调频使用
      t.string :base_currency
      t.boolean :portfolioable
      t.string :updated_by
      t.date :trading_since
      t.string :source

      t.timestamps
    end
  end
end
