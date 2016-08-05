class ChannelLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :date, type: Date
  field :channel_id
  field :views_count, type: Integer, default: 0
  field :visits_count, type: Integer, default: 0 # 30分钟内算一次
  field :uv_count, type: Integer, default: 0 # 当天
  field :downloads_count, type: Integer, default: 0

  def self.incre_views(channel_id, fields)
    today_log(channel_id).incre_views(fields)
  end

  def self.incre_downloads(channel_id)
    today_log(channel_id).incre_downloads
  end

  def self.today_log(channel_id)
    self.find_or_create_by(channel_id: channel_id, date: Date.today)
  end

  def incre_views(fields)
    attrs = {}
    fields.each{|f| attrs[f] = 1 }
    inc(attrs)
  end

  def incre_downloads
    inc(downloads_count: 1)
  end

  def self.statistics(channel_ids, start_date = Date.today, end_date = Date.today)
    start_date = Date.parse(start_date) if start_date.is_a? String
    end_date = Date.parse(end_date) if end_date.is_a? String
    logs = self.where(:channel_id.in => channel_ids, :date.gte => start_date, :date.lte => end_date).to_a
    logs.group_by(&:channel_id).map do |channel_id, group|
      [channel_id, {views: group.map(&:views_count).sum.to_i, downloads: group.map(&:downloads_count).sum.to_i, visits: group.map(&:visits_count).sum.to_i, uv: group.map(&:uv_count).sum.to_i}]
    end.to_h
  end
end