class AddColumnsToStockScreener < ActiveRecord::Migration
  def change
    add_column :stock_screeners, :pe, :decimal, precision: 18, scale: 6, default: 0.0, comment: "市盈率"
    add_column :stock_screeners, :pe_c, :decimal, precision: 18, scale: 6, default: 0.0
    add_column :stock_screeners, :pe_r, :decimal, precision: 18, scale: 6, default: 0.0
    add_column :stock_screeners, :lpg, :decimal, precision: 18, scale: 6, default: 0.0, comment: "长期盈利增长"
    add_column :stock_screeners, :lpg_c, :decimal, precision: 18, scale: 6, default: 0.0
    add_column :stock_screeners, :lpg_r, :decimal, precision: 18, scale: 6, default: 0.0
    add_column :stock_screeners, :cf, :decimal, precision: 18, scale: 6, default: 0.0, comment: "现金流"
    add_column :stock_screeners, :cf_c, :decimal, precision: 18, scale: 6, default: 0.0
    add_column :stock_screeners, :cf_r, :decimal, precision: 18, scale: 6, default: 0.0
    add_column :stock_screeners, :gm, :decimal, precision: 18, scale: 6, default: 0.0, comment: "毛利润率"
    add_column :stock_screeners, :gm_c, :decimal, precision: 18, scale: 6, default: 0.0
    add_column :stock_screeners, :gm_r, :decimal, precision: 18, scale: 6, default: 0.0
    add_column :stock_screeners, :wst, :decimal, precision: 18, scale: 6, default: 0.0, comment: "华尔街目标价格"
    add_column :stock_screeners, :wst_c, :decimal, precision: 18, scale: 6, default: 0.0
    add_column :stock_screeners, :wst_r, :decimal, precision: 18, scale: 6, default: 0.0
    add_column :stock_screeners, :div, :decimal, precision: 18, scale: 6, default: 0.0, comment: "现金分红"
    add_column :stock_screeners, :div_c, :decimal, precision: 18, scale: 6, default: 0.0
    add_column :stock_screeners, :div_r, :decimal, precision: 18, scale: 6, default: 0.0
    
    add_column :stock_screeners, :c1, :integer
    add_column :stock_screeners, :c2, :integer
    add_column :stock_screeners, :c3, :integer
    add_column :stock_screeners, :c4, :integer
    add_column :stock_screeners, :c5, :integer
    add_column :stock_screeners, :c6, :integer
    add_column :stock_screeners, :c7, :integer
    add_column :stock_screeners, :c8, :integer
    add_column :stock_screeners, :c9, :integer
    add_column :stock_screeners, :c10, :integer
    add_column :stock_screeners, :c11, :integer
    add_column :stock_screeners, :c12, :integer
    add_column :stock_screeners, :c13, :integer
    add_column :stock_screeners, :c14, :integer
    add_column :stock_screeners, :c15, :integer
    add_column :stock_screeners, :c16, :integer
    add_column :stock_screeners, :c17, :integer
    add_column :stock_screeners, :c18, :integer
    add_column :stock_screeners, :c19, :integer
    add_column :stock_screeners, :c20, :integer
    
  end
end
