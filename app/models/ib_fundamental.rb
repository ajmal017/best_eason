class IbFundamental < ActiveRecord::Base
  
  def self.request
    if (stock_id = $redis.get("request_fundamental_stock_id")).present?
      stock = BaseStock.normal.except_cn.find_by(id: stock_id)
      if stock
        stock.request_fundamental 
        stock_id = BaseStock.normal.except_cn.order("id asc").where("id > ?", stock.id).limit(1).first.try(:id)
      else
        stock_id = BaseStock.normal.except_cn.order("id asc").limit(1).first.id
      end
      $redis.set("request_fundamental_stock_id", stock_id)
    else
      stock = BaseStock.normal.except_cn.order("id asc").limit(1).first
      stock.request_fundamental
      stock_id = BaseStock.normal.except_cn.order("id asc").where("id > ?", stock.id).limit(1).first.try(:id)
      $redis.set("request_fundamental_stock_id", stock_id)
    end
  end
  
end
