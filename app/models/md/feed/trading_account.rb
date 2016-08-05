class MD::Feed::TradingAccount < MD::Feed
  
  def set_data(attrs={})
    self.data = {broker_name: source.broker.try(:cname)}
  end
  
  def title
    "绑定了#{broker_name}"
  end
  
  def broker_name
    data[:broker_name] || "券商交易账户"
  end
  
end