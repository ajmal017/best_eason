class StaticContent < ActiveRecord::Base
  include Followable
  include Commentable

  before_create :save_info

  TYPE = %w[ ES::Announcement MD::Data::SpiderNews ]

  def save_info
    self.data = sourceable.data
    self.title = sourceable.title
  end

  def sourceable
    @sourceable ||= DbAdapter::Base.new(sourceable_type.constantize).find(sourceable_id)
  end

  def data
    @data ||= JSON.parse(super || "")
  end

  def data=(data)
    super(data.to_json)
  end

  def show_info
    data
  end

  def source_info
    title
  end

  def self.get(record)
    TYPE.include?(record.class.name) ? StaticContent.find_or_create_by(sourceable_type: record.class.name, sourceable_id: record.id.to_s) : record
  end
  
  def comment_feed_type
    case sourceable_type.to_s
    when "MD::Data::SpiderNews"
      :news_comment
    when "ES::Announcement"
      nil # 暂无
    end
  end

  def final_path
    case sourceable_type.to_s
    when "MD::Data::SpiderNews"
      "news"
    when "ES::Announcement"
      nil # 暂无评论
    end
  end
  
  def ext_data_for_feed
    data.slice(*["source", "category"])
  end
end
