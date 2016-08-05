module ConvertBody
  extend ActiveSupport::Concern
  included do
    before_save :convert_body, if: "self.text_changed?"
  end

  def convert_body
    link_mentioned_usernames
    link_mentioned_stocks
  end

  def link_mentioned_usernames
    self.body = Caishuo::Utils::Text.auto_link_usernames(self.text)
  end

  def link_mentioned_stocks
    self.body = Caishuo::Utils::Text.auto_link_stocks(self.body)
  end

end
