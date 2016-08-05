# 重新生成topics zxg合作静态页面
class StaticHtmlCleanerWorker
  @queue = :static_html_cleaner_worker

  def self.perform
    FileUtils.rm_r("#{Rails.root}/public/caches/market/zxg/topics") rescue nil

    Topic.where(visible: true).select(:id).each do |topic|
      `curl #{Setting.host}/market/zxg/topics/#{topic.id}.html`
      sleep 0.1
    end
  end
end
