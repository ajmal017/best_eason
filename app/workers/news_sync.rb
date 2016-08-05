class NewsSync
  @queue = :news_sync

  def self.perform
    ES::Source.all.each do |s|
      Spider::Crawler.run(s.code)
    end
  end
end

