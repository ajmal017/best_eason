class CreatePortfolios < ActiveRecord::Migration
  def change
    create_table :portfolios, force: true do |t|
      t.integer :base_stock_id
      t.integer :user_id
      t.integer :position
      t.string :currency
      t.string :symbol
      t.integer :contract_id
      t.decimal :market_price, precision: 16, scale: 10
      t.decimal :market_value, precision: 25, scale: 10, default: 0.0
      t.decimal :average_cost, precision: 16, scale: 10
      t.decimal :unrealized_pnl, precision: 16, scale: 10
      t.decimal :realized_pnl, precision: 16, scale: 10
      t.string :account_name
      t.string :updated_by

      t.timestamps
    end
    
    add_index :portfolios, :user_id
    add_index :portfolios, [:user_id, :base_stock_id]
  end
end
