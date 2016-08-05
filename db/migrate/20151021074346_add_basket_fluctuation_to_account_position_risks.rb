class AddBasketFluctuationToAccountPositionRisks < ActiveRecord::Migration
  
  def change
    # 组合波动率
    add_column :account_position_risks, :basket_fluctuation, :float
  end

end
