class ChannelCode < ActiveRecord::Base

  validates :code, uniqueness: true, presence: true, length: {minimum: 2, maximum: 50}
  validates :media, presence: true, length: {minimum: 2, maximum: 16}
  validates :ad_type, uniqueness: {scope: "code"}, length: {maximum: 16}

  include Redis::Objects

  counter :visits
  counter :downloads

  DEFAULT_APK = Setting.app.apk.default

  AD_TYPES = {
    "电子邮件" => {email: "邮件"}, 
    "一般付费搜索" => {
      cpc: "点击广告（一般按一千个ip计算）",
      ppc: "竞价广告"
    },
    "社交" => {
      social: "微博、微信、SNS等"
    },
    "展示广告" => {
      cpm: "展示广告（展示广告，一般的视频比较多）"
    }
  }.transform_values!{|items| items.map{|k, v| ["#{k} #{v}", k]} }
  

  before_validation :set_data
  def set_data
    self.code = [media, ad_type].find_all{|x| x.present?} * "_"
  end


  def url
    "http://#{$mobile_domain}/market/download?channel=#{code}"
  end

  def ga_url
    attrs = {utm_source: media, utm_medium: ad_type, utm_campaign: "{计划名}", utm_term: "{关键字}", utm_content: "{创意}"}
    # 不能用to_param  顺序会乱
    "#{url}&#{attrs.map{|k,v|"#{k}=#{v}"} * "&"}"
  end

  def pretty_ga_url
    attrs = {channel: code, utm_source: media, utm_medium: ad_type, utm_campaign: "{计划名}", utm_term: "{关键字}", utm_content: "{创意}"}
    # 不能用to_param  顺序会乱
    "http://#{$mobile_domain}/market/download?#{attrs.map{|k,v|"#{k}=<b class='red'>#{v}</b>"} * "&"}"
  end


  def self.find_channel(code)
    return if code.blank?
    ChannelCode.where(code: code).last
  end

  def self.download(code, log_count = false)
    channel_code = ChannelCode.find_channel(code)
    return DEFAULT_APK if channel_code.blank? or channel_code.status != 1
    channel_code.incre_downloads if log_count
    channel_code.apk_url
  end

  def status_name
    %w{关闭 开启}[status]
  end

  def status_toggle
    status == 1 ? 0 : 1
  end

  def apk_url
    super || "http://static.caishuo.com/downloads/caishuo_#{code}.apk"
  end

  def incre_views(fields)
    ChannelLog.incre_views(id, fields)
  end

  def incre_downloads
    ChannelLog.incre_downloads(id)
  end
end