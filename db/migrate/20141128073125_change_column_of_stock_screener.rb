class ChangeColumnOfStockScreener < ActiveRecord::Migration
  def change
    change_column :stock_screeners, :country_usa, :boolean, default: false
    change_column :stock_screeners, :country_can, :boolean, default: false
    change_column :stock_screeners, :country_isr, :boolean, default: false
    change_column :stock_screeners, :country_chn, :boolean, default: false
    change_column :stock_screeners, :country_others, :boolean, default: false
  end
end
