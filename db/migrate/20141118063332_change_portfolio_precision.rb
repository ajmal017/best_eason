class ChangePortfolioPrecision < ActiveRecord::Migration
  def change
    change_column :portfolios, :unrealized_pnl, :decimal, precision: 25, scale: 10, default: 0.0
    change_column :portfolios, :realized_pnl, :decimal, precision: 25, scale: 10, default: 0.0
    
    change_column :portfolio_archives, :unrealized_pnl, :decimal, precision: 25, scale: 10, default: 0.0
    change_column :portfolio_archives, :realized_pnl, :decimal, precision: 25, scale: 10, default: 0.0
  end
end
