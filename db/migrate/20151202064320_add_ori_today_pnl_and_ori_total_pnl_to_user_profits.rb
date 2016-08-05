# 添加账户原始货币单位的pnl字段
class AddOriTodayPnlAndOriTotalPnlToUserProfits < ActiveRecord::Migration
  def change
    add_column :user_profits, :ori_today_pnl, :decimal, precision: 16, scale: 3, default: 0.0, comment: "原始货币pnl，today_pnl是转后成usd的"
    add_column :user_profits, :ori_total_pnl, :decimal, precision: 16, scale: 3, default: 0.0
  end
end
