class DataCheck::Notice
  @queue = :data_check
  
  def self.perform(content)
    Caishuo::Utils::Email.deliver(Setting.investment_notifiers.email, content, Rails.env)
  end

end
