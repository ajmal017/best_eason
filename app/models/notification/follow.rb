class Notification::Follow < Notification::Base
  def gen_content
    self.content = case self.mentionable_type
      when "Basket"
        then gen_notification_for_basket
      else
        logger.info "mentionable_type processing is missing"
        nil
      end
  end

  private
  def gen_notification_for_basket
    link_url, link_title = "/baskets/#{self.mentionable_id}", self.mentionable.title
    basket_content_template(link_url, link_title)
  end

  def basket_content_template(link_url, link_title)
    "#{triggered_user.username}关注了您创建的投资主题《<a href='#{link_url}' target='_blank'>#{link_title}</a>》。"
  end
end