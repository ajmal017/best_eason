class Notification::Position < Notification::Base
  include Countable
  include PushNotification

  belongs_to :basket, class_name: "Basket", foreign_key: :mentionable_id
  attr_accessor :stock_adjust_count

  def stock_adjust_count
    @stock_adjust_count || 0
  end

  def self.add(notice_user_id, triggered_user_id, mentionable, sac)
    return true if notice_user_id == triggered_user_id
    
    self.create({
      :user_id => notice_user_id, 
      :triggered_user_id => triggered_user_id, 
      :mentionable => mentionable, 
      :originable => nil,
      :stock_adjust_count => sac
    })
  end

  def url
    "/baskets/#{mentionable_id}"
  end

  private

  def gen_title
    self.title = "组合\"#{basket.title}\""
  end

  def gen_content
    #adjustment_log = self.basket.basket_adjustments.first.basket_adjust_logs_desc.first rescue nil
    #action_message = adjustment_log.present? ? "操盘人#{adjustment_log.action_desc}#{adjustment_log.stock.c_name}" : ""
    #self.content = "您关注的组合 #{basket.title} 调仓了。" + action_message
    self.content = "#{basket.author.username}调整了#{stock_adjust_count}只股票"
  end
end
