class Follow::Base < ActiveRecord::Base
  self.table_name = :follows

  include Taggable  #user
  include Feedable

  validates :user_id, :type, presence: true
  validates :followable_type, :followable_id, presence: true
  validates :followable_id, :uniqueness => {:scope => [:user_id, :followable_type]}
  validates :notes, custom_length: {max: 300, message: "长度不合法"}

  belongs_to :followable, polymorphic: true, counter_cache: :follows_count
  belongs_to :user, class_name: "::User"
  alias :follower :user

  FAVORITE_NAMES = %w[ Topic Article StaticContent ]
  FAVORITE_TYPES_KLASS = {
    "topic" => Topic,
    "article" => Article,
    "announcement" => ES::Announcement,
    "news" => MD::Data::SpiderNews,
  }
  FAVORITE_TYPES = FAVORITE_TYPES_KLASS.keys

  FEED_TYPE_MAPPINGS = {"BaseStock" => :stock_follow, "Basket" => :basket_follow, "User" => :friend }

  scope :for_stock, -> { where(followable_type: 'BaseStock') }
  scope :for_basket, -> { where(followable_type: 'Basket') }
  scope :for_user, -> { where(followable_type: 'User') }
  scope :selected, -> { where(followable_type: ['Basket', 'BaseStock']) }
  scope :by_user, -> (user_id) { where(user_id: user_id) }
  scope :sort, -> { order("sort, created_at desc") }
  scope :favorites, -> { where(followable_type: FAVORITE_NAMES) }

  before_create :set_feed_type
  after_commit :followings_counter_cache, on: [:create, :destroy]
  after_create :send_notification

  def real_followable_type
    @real_followable_type ||=
      if followable_type == "StaticContent"
        ::Follow::Base::FAVORITE_TYPES_KLASS.invert[followable.sourceable_type.constantize]
      else
        ::Follow::Base::FAVORITE_TYPES_KLASS.invert[followable_type.constantize]
      end
  end

  def real_followable_id
    @real_followable_id ||=
      if followable_type == "StaticContent"
        followable.sourceable_id
      else
        followable_id
      end
  end

  def real_followable_url
    ::Page.new(real_followable_type.pluralize, real_followable_id).url if FAVORITE_NAMES.include? followable_type
  end
  
  private

  def set_feed_type
    self.feed_type = FEED_TYPE_MAPPINGS[followable_type]
  end

  def followings_counter_cache
    Resque.enqueue(UserCounterCacheWorker, user_id, followable_type)
  end

  def send_notification
    # 要求：所有followable都需要user_id的field or method
    send_notice_types = ['Basket']
    Notification::Follow.add(followable.user_id, user_id, followable) if send_notice_types.include?(followable_type)
  end
end