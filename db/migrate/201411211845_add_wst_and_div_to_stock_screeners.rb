class AddWstAndDivToStockScreeners < ActiveRecord::Migration
  def change
    # add_column :stock_screeners, :wst_2, :decimal, precision: 18, scale: 6, default: 0.0, comment: "华尔街目标价格，wst为比例"
    # add_column :stock_screeners, :div_2, :decimal, precision: 18, scale: 6, default: 0.0, comment: "现金分红，div为比例"
  end
end