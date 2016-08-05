class AddColumnsToScreener < ActiveRecord::Migration
  def change
    add_column :stock_screeners, :country_hkg, :boolean, default: false, comment: "香港"
    
    add_column :stock_screeners, :capitalization_pe10, :boolean, default: false, comment: "PE < 10"
    add_column :stock_screeners, :capitalization_dy4, :boolean, default: false, comment: "股息收益率 > 4%"
    add_column :stock_screeners, :capitalization_clb, :boolean, default: false, comment: "市值低于账面价值"
    add_column :stock_screeners, :capitalization_cl1s, :boolean, default: false, comment: "市值低于1倍销售额"
    add_column :stock_screeners, :capitalization_cl7p, :boolean, default: false, comment: "市值低于7倍经营利润"
  end
end
