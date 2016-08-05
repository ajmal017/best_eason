class Array
  def has_all_detail_elements?
    self.all? { |e| e.is_a?(CaishuoMQ::Consumer::Handler::Detail) }
  end
  
  def has_all_array_elements?
    self.all? { |e| e.is_a?(Array) }
  end
  
  def has_all_order_data_elements?
    self.all? { |e| e.is_a?(CaishuoMQ::Consumer::Handler::OrderData) }
  end
  
  def has_all_hash_elements?
    self.all? { |e| e.is_a?(Hash) }
  end
end