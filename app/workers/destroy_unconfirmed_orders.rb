class DestroyUnconfirmedOrders
  @queue = :destroy_unconfirmed_orders

  def self.perform
  	# 该时间可以在/admin/configs 配置
    hours = Configs.unconfirmed_orders_hours
    Order.unconfirmed.where("created_at < ?", hours.hours.ago).destroy_all
  end
end