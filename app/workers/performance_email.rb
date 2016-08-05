class PerformanceEmail
  @queue = :performance
  
  # 临时测试用
  def self.perform(content, title)
    title = title.to_s + Rails.env
    Caishuo::Utils::Email.deliver('dongshuxiang@caishuo.com', content, title)
  end
end
