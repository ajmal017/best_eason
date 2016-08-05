class CreatePortfolioArchives < ActiveRecord::Migration
  def change
    create_table :portfolio_archives do |t|
      t.integer :user_id
      t.integer :base_stock_id
      t.date :archive_date
      t.integer :position
      t.string :currency
      t.string :symbol
      t.integer :contract_id
      t.string :account_name
      t.string :updated_by
      t.decimal :market_price, precision: 16, scale: 10
      t.decimal :market_value, precision: 25, scale: 10, default: 0.0
      t.decimal :average_cost, precision: 16, scale: 10
      t.decimal :unrealized_pnl, precision: 16, scale: 10
      t.decimal :realized_pnl, precision: 16, scale: 10

      t.timestamps
    end
    
    add_index :portfolio_archives, [:user_id, :base_stock_id, :archive_date], name: 'unique_index_portfolio_archives', unique: true
  end
end
