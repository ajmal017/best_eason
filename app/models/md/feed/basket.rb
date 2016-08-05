class MD::Feed::Basket < MD::Feed
  # feed_type: basket_create, basket_adjust...
  
  def set_data(attrs={})
    push_new_items
    self.title = source.title
  end
  
  def push_new_items
    items.push MD::ItemBasket.new(id: source.id, name: source.title, type: :basket)
    if feed_type == :basket_adjust
      source.latest_adjustment.generate_logs
      log = source.latest_adjustment.basket_adjust_logs.except_cash.reload.first
      items.push MD::ItemBasketAdjustLog.new(id: log.id, ext_data: log.datas_for_feed, type: :basket_adjust_log) if log
    end
  end

end