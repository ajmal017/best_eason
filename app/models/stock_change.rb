class StockChange < ActiveRecord::Base
  def before_split
    factor.split(":")[0].to_f
  end
  
  def after_split
    factor.split(":")[1].to_f
  end
end
