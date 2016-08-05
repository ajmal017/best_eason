class SendPositionNotificationWorker
  @queue = :send_position_notification

  def self.perform(id, ba_id)
    basket = Basket.find(id)
    basket_adjustment = BasketAdjustment.find(ba_id)

    basket.followers.each do |user|
      Notification::Position.add(user.id, nil, basket, basket_adjustment.basket_adjust_logs.changed.except_cash.size) unless user.id == basket.author_id
    end if basket.present?
  end
end
