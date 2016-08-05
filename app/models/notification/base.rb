class Notification::Base < ActiveRecord::Base
  self.table_name = 'notifications'

  MENTIONABLE_TYPE_MAP = {
    "BaseStock" => "stock",
    "Basket" => "basket"
  }

  include AccessDbRelate
  
  validates :user_id, presence: true
  belongs_to :mentionable, polymorphic: true
  belongs_to :user
  belongs_to :triggered_user, class_name: 'User', foreign_key: :triggered_user_id
  # 原始对象
  belongs_to :originable, polymorphic: true
  belongs_to :targetable, polymorphic: true

  delegate :url_helpers, to: 'Rails.application.routes'

  scope :unread, -> { where(read: false) }
  scope :by_user, -> (user_id) { where(user_id: user_id) }
  scope :any_of_comment_or_like, -> { where(type: ['Notification::Comment', 'Notification::Like']) }
  scope :app_notification_types, -> { where(type: ['Notification::System', 'Notification::Position', 'Notification::StockReminder']) }
  scope :app_news_types, -> { where(type: ['Notification::Like', 'Notification::Comment', 'Notification::Mention']) }
  scope :system, -> { where(type: 'Notification::System') }
  scope :stock, -> { where(type: 'Notification::StockReminder') }
  scope :position, -> { where(type: 'Notification::Position') }
  scope :globle, -> { where(type: 'Notification::Globle') }
  scope :sort_desc, -> { order(id: :desc) }
  scope :displayable, -> { where.not(originable_id: nil) }

  before_validation :gen_content, on: :create
  before_validation :gen_title, on: :create, if: -> { %w[Position StockReminder System].include? self.class.name.demodulize }

  def self.add(notice_user_id, triggered_user_id, mentionable, originable = nil)
    return true if notice_user_id == triggered_user_id
    
    self.create({
      :user_id => notice_user_id, 
      :triggered_user_id => triggered_user_id, 
      :mentionable => mentionable, 
      :originable => originable
    })
  end

  def self.get_counters(user_id)
    $cache.hgetall("user:#{user_id}:notifications")
  end
  
  def safe_content
    Sanitize.clean(content, SanitizeRules::BASIC)
  end
  
  def targetable_url_path
    case targetable
    when BaseStock
      'stock_path'
    when StaticContent
      'news_path'
    else
      targetable.class.table_name.singularize + '_path'
    end
  end

  def content
    read_attribute(:content).to_s
  end

  def title
    read_attribute(:title).to_s
  end

  def targetable_human_name
    return "新闻" if targetable.is_a?(StaticContent)

    targetable ? targetable.class.model_name.human : ""
  end

  def targetable_title
    return "" unless targetable

    targetable.is_a?(BaseStock) ? (targetable.c_name || targetable.name) : targetable.title
  end

  def targetable_link_url
    return "/news/#{targetable.sourceable_id}" if targetable.is_a?(StaticContent)
    
    targetable ? url_helpers.send(targetable_url_path, targetable) + "#Comments" : ""
  end

  def mentionable_type_map
    MENTIONABLE_TYPE_MAP[mentionable_type] || mentionable_type
  end

  private
end
