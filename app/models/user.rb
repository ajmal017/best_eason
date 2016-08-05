require "forwardable"
class User < ActiveRecord::Base
  ACCESSABLE_FIELDS = [:username, :email, :password, :password_confirmation, :invitation_token, :province, :city, :gender, :biography, :crop_x, :crop_y, :crop_h, :crop_w, :remember_me, :current_password, :copy_temp_image]

  MALE = true
  FEMALE = false
  GENDERS = {"男" => true, "女" => false}.invert

  CONFIRMATION_LIMIT = 3
  enum status: [:normal ,:blocked]

  attr_accessor :password, :password_confirmation, :crop_x, :crop_y, :crop_w, :crop_h, :crop_t, :invitation_token, :current_password, :captcha, :copy_temp_image

  include PrettyIdable
  include Mongoable
  include Followable

  validates :email, uniqueness: true, format: { with: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i }, allow_nil: true

  validates :username, custom_length: {min: 1, max: 80, message: "长度不合法"}, sensitive: -> {username_changed?}, allow_nil: true
  validate ->{ errors.add(:username, :repeat) unless User.username_avaliable?(username, id) }, if: -> { username_changed? }

  validates :headline, custom_length: {min: 4, max: 30, message: "长度不合法"}, sensitive: true, allow_blank: true, if: :headline_changed?

  validates :password, presence: true, confirmation: true, length: {minimum: 6, maximum: 20}, format: { with: /\A[~!@#\$%\^&\*\(\)_\+=\-`,\.\/;\[\]\\\|}{:?><a-zA-Z0-9]{6,20}\Z/, message: "格式不合法" }, if: Proc.new{|u| u.password }

  validates :mobile, uniqueness: true, allow_nil: true

  #validate :at_least_one_of_email_and_mobile

  has_many :send_invitations, class_name: 'Invitation', foreign_key: 'sender_id'
  belongs_to :invitation

  has_one :pt_application

  has_many :followings, class_name: "Follow::User"   #我关注的
  has_many :followed_users, -> { order "follows.created_at DESC" }, through: :followings, source: :followable, source_type: :User #我关注的人

  # 订阅
  has_many :subscriptions
  has_many :feeds, through: :subscriptions

  # 投票
  has_many :votes

  # 用户评论
  has_many :comments

  # 专栏文章
  has_many :articles

  # 好友
  has_many :friends, -> { where(friend: true).order(created_at: :desc) }, class_name: 'Follow::User', foreign_key: 'user_id'

  # 私信
  has_many :receive_messages, foreign_key: :receiver_id, class_name: 'Message', dependent: :destroy
  has_many :send_messages, foreign_key: :sender_id, class_name: 'Message', dependent: :destroy

  # 用户临时头像
  has_one :temp_image, as: :resource, class_name: 'Upload::User', dependent: :destroy

  # 主题
  has_many :baskets, foreign_key: :author_id
  has_many :following_baskets, -> { where(followable_type: 'Basket') }, class_name: 'Follow::Basket', foreign_key: :user_id
  has_many :following_stocks, -> { where(followable_type: 'BaseStock') }, class_name: 'Follow::Stock', foreign_key: :user_id

  # 订单
  has_many :orders
  has_many :buy_orders, -> { where(:type => "OrderBuy") }, class_name: "OrderBuy"
  has_many :sell_orders, -> { where(:type => "OrderSell") }, class_name: "OrderSell"

  has_many :basket_orders, -> { where.not(basket_id: nil) }, class_name: "Order"
  has_many :stock_orders, -> { where(basket_id: nil) }, class_name: "Order"

  # 用户购买的主题投资
  has_many :buying_baskets, through: :orders, source: :basket

  # 用户购买的所有stock信息
  has_many :order_details

  has_many :positions
  has_many :basket_positions, -> { where.not(instance_id: ["others", "unallocate"]) }, class_name: "Position"

  has_many :others_positions, -> { where(instance_id: "others") }, class_name: "Position"

  has_many :caishuo_positions, -> { where.not(instance_id: "others") }, class_name: "Position"

  has_many :unallocate_positions, -> { where(instance_id: "unallocate") }, class_name: "Position"

  has_many :allocate_positions, -> { where.not(instance_id: "unallocate") }, class_name: "Position"

  has_many :portfolios

  has_many :position_deltas

  has_many :notifications, -> { order("notifications.id desc") }, class_name: 'Notification::Base', foreign_key: :user_id

  has_many :user_bindings, class_name: 'TradingAccount'

  has_many :trading_accounts, dependent: :destroy

  # 未读各种消息
  has_one :counter, dependent: :destroy

  # 账户净值
  has_many :user_day_properties, dependent: :destroy

  has_many :follow_stock_tags, class_name: 'Tag::FollowStock', foreign_key: :user_id

  # 用户app端隐私
  has_one :app_permission, dependent: :destroy

  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile

  # app token
  has_many :api_tokens

  # 实名认证
  has_one :user_certification

  # 股价提醒
  has_many :stock_reminders, dependent: :destroy do
    def by_stock(stock_id)
      self.where(stock_id: stock_id)
    end

    def by_stock_result(stock_id)
      srs = by_stock(stock_id)
      result = {}
      StockReminder::REMINDER_TYPES.each{ |type| result[type.to_sym] = srs.find{|sr| sr.reminder_type == type }.try(:reminder_value) }
      result
    end
  end

  # 用户头像
  mount_uploader :avatar, UserAvatar

  scope :created_at_gte, -> (date_str) { date_str.present? ? where("created_at >= ?", Date.parse(date_str)) : all}
  scope :created_at_lte, -> (date_str) { date_str.present? ? where("created_at <= ?", Date.parse(date_str) + 1) : all}

  def self.pc_app_channel(str)
    if str == "app"
      where(source: "app")
    elsif str == "pc"
      self.where("source is NULL")
    else
      all
    end
  end


  # 关联的user_binding
  def user_binding
    user_bindings.first
  end

  def self.username_avaliable?(username, user_id = nil)
    formated_username = username.full_width_tr
    return false unless ForbiddenName.usable?(formated_username)
    return false unless Caishuo::Utils::TextFilter.clean?(formated_username)
    User.where('username = ?', formated_username).where.not(id: user_id).blank?
  end

  # 用户临时头像
  # mount_uploader :logo, UserAvatar

  # 设置图像
  before_save :set_avatar
  def set_avatar
    if copy_temp_image.present?
      self.avatar = self.temp_image.image.large
      self.write_avatar_identifier
    end
  end
  # if self.temp_image.blank? || self.temp_image.image.blank?
  #  self.avatar = File.open(Rails.root + 'app/assets/images/test.jpg')
  # else
  #  self.avatar = self.temp_image.image
  # end

  # 裁剪图片
  # after_update :crop_avatar
  def crop_avatar
    avatar.recreate_versions! if cropping?
  end

  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end

  before_save :check_invite_code, if: Proc.new{ |user| user.invite_code.present? && user.invite_code_changed? }
  def check_invite_code
    invite = InvitationCodeSuper.find_by(code: self.invite_code)
    self.invite_code = invite_code_was unless invite
  end

  after_save :set_invite_token_status, if: Proc.new{ |user| user.invite_code.present? && user.invite_code_changed? }
  def set_invite_token_status
    invite = InvitationCodeSuper.find_by(code: self.invite_code)
    invite.increment!(:invitation_limit) if invite
  rescue
    true
  end

  # 当用户名为空或者重复时，设置默认用户名
  before_validation :set_default_username, on: [:create], if: Proc.new{ |user| user.username.blank? || User.exists?(username: user.username) }
  def set_default_username
    uname = username.blank? ? 'C' : username
    uname += "#{Time.now.to_i}#{rand(1000)}".to_i.to_s(36).rjust(6, '0').upcase
    self.username = uname
  rescue
    true
  end

  def checked_at
    super || created_at
  end

  def get_app_permission
    app_permission || AppPermission.new
  end

  def resend_confirmation_and_set_invite_token_status
    self.send_on_create_confirmation
    self.set_invite_token_status if self.invite_code.present?
  end

  # 返回当前follow状态
  def follow_user(user)
    return false if user.id == id
    user.follow_or_unfollow_by_user(id)
  end

  # 关注
  def followed?(user_id)
    return false unless user_id.present?
    return true if user_id == id
    Follow::User.exists?(user_id: id, followable_id: user_id)
  end

  def followed_by?(user)
    followed_by_user?(user.try(:id))
  end

  # 朋友
  def friend?(friend_id)
    Follow::User.exists?(user_id: id, followable_id: friend_id, friend: true)
  end

  #是否持有股票
  def positioned?(stock_id)
    Position.where(trading_account_id: TradingAccount.binded.by_user(self.id).ids).where("base_stock_id = ? AND shares > ?", stock_id, 0).any?
  end

  def self.send_welcome_message(caishuo_user, sended_user)
    content = "欢迎加入财说！我是财说小秘书。财说目标是打造最好用的全球股票交易平台，您可以尝试着去建一些喜爱的投资组合，也可以参与到其他热点组合的讨论中，与大家交换心得。如果您在使用中遇到任何问题，可随时通过电话联系我们（财说专线：400-771-8858）或私信回复我留言。"
    Message.add(caishuo_user.id, sended_user.id, content)
  end

  def follow_caishuo
    caishuo_user = User.find_by_id(Setting.auto_followed_user_id)
    self.follow_user(caishuo_user)
    User.send_welcome_message(caishuo_user, self)
  rescue
  end

  def pretty_followings_count(unit=nil)
    default_user? ? "--#{unit}" : "#{followed_users_count.to_i}#{unit}"
  end

  def pretty_fans_count(unit=nil)
    default_user? ? "--#{unit}" : "#{follows_count.to_i}#{unit}"
  end

  def default_user?
    id == Setting.auto_followed_user_id
  end

  def unread_message_count
    receive_messages.unread.count
  end

  # 未读私信数量
  def unread_msg_count_by_redis
    Message.new.unread_counts.get(id).to_i
  end

  def reset_confirmation_count
    update(confirmation_count: 1)
  end

  def can_selled_shares_of(stock_id)
    others_shares_of(stock_id)
  end

  def basket_shares_of(stock_id)
    self.basket_positions.stock_id_with(stock_id).inject(0) { |sum, pos| sum + pos.shares.to_i }
  end

  def shares_of(instance_id, stock_id)
    self.basket_positions.instance_with(instance_id).stock_id_with(stock_id).inject(0) { |sum, pos| sum + pos.can_selled_shares }
  end

  def others_shares_of(stock_id)
    self.others_positions.stock_id_with(stock_id).inject(0) { |sum, pos| sum + pos.can_selled_shares }
  end

  def total_shares_of(stock_id)
    self.allocate_positions.stock_id_with(stock_id).inject(0) { |sum, pos| sum + pos.shares.to_i }
  end

  def caishuo_shares(stock_id)
    self.allocate_positions.stock_id_with(stock_id).inject(0) { |sum, pos| sum + pos.shares.to_i }
  end

  def allocate_shares(stock_id)
    self.allocate_positions.stock_id_with(stock_id).inject(0) { |sum, pos| sum + pos.shares.to_i }
  end

  def total_cost(stock_id)
    self.caishuo_positions.stock_id_with(stock_id).inject(0) { |sum, pos| sum + pos.shares.to_i * pos.average_cost }
  end

    def basket_shares_of(stock_id)
      self.basket_positions.stock_id_with(stock_id).inject(0) { |sum, pos| sum + pos.shares.to_i }
    end

    def shares_of(instance_id, stock_id)
      self.basket_positions.instance_with(instance_id).stock_id_with(stock_id).inject(0) { |sum, pos| sum + pos.can_selled_shares }
    end

    def others_shares_of(stock_id)
      self.others_positions.stock_id_with(stock_id).inject(0) { |sum, pos| sum + pos.can_selled_shares }
    end

    def total_shares_of(stock_id)
      self.allocate_positions.stock_id_with(stock_id).inject(0) { |sum, pos| sum + pos.shares.to_i }
    end

    def caishuo_shares(stock_id)
      self.allocate_positions.stock_id_with(stock_id).inject(0) { |sum, pos| sum + pos.shares.to_i }
    end

    def allocate_shares(stock_id)
      self.allocate_positions.stock_id_with(stock_id).inject(0) { |sum, pos| sum + pos.shares.to_i }
    end

    def total_cost(stock_id)
      self.caishuo_positions.stock_id_with(stock_id).inject(0) { |sum, pos| sum + pos.shares.to_i * pos.average_cost }
    end

    def adjust_position_shares(stock_id, split)
      self.positions.stock_id_with(stock_id).each { |p| p.update_attributes(shares: p.shares.to_i * split) }
    end

    def portfolio_position(stock_id)
      self.portfolios.where(base_stock_id: stock_id).first.try(:position).try(:to_i)
    end

    def position_delta(stock_id)
      self.position_deltas.with_stock(stock_id).first.try(:delta)
    end

    def position_changed_of(stock_id)
      self.portfolios.where(base_stock_id: stock_id).first.position.to_i - self.positions.map(&:shares).compact.sum.to_i
    end

    def unread_notifications
      self.notifications.unread
    end

    def has_unread_notices?
      unread_notifications.count > 0
    end

    # 是否购买主题
    def buyed_basket?(original_basket_id)
      positions.where(instance_id: original_basket_id).any?{ |x| x.shares > 0 }
    end

    # 基本货币单位
  def base_currency
    @base_currency || ( @base_currency = user_bindings.first.try(:base_currency) )
  end

  def gender_name
    GENDERS[self.gender]
  end

  include Accountable
  def password=(password)
    @password = password
    self.encrypted_password = password_digest(@password) if @password.present?
  end

  def email=(email)
    write_attribute(:email, email.downcase)
  end

  #def username
    #super || default_username
  #end

  def username=(username)
    write_attribute(:username, username.full_width_tr)
  end

  #def default_username
    #"cs_#{email.gsub(/@.*$/, "") rescue mobile}"
  #end

  def reconcile
    self.portfolios.map(&:reconcile)
  end

  def has_binding_account?
    user_bindings.present?
  end

  # def position_count_for_menu
  #   Position.buyed_count_for_menu(self.id)
  # end

  # 未使用
  # def basket_count_for_menu
  #   [self.baskets.custom.count,
  #    self.baskets.normal.not_archived.count,
  #    Follow::Stock.followed_stocks_by(self.id).count].sum
  # end

  def unreconciled_symbols
    $pms_logger.info("ExecDetails Tws: exec所传来的都已调平，现在检查是否所有symbol均已调平") if Setting.pms_logger
    symbols = []
    self.portfolios.each do |pf|
      symbols << pf.base_stock.split(self) unless pf.reconciled?
    end
    symbols.compact
  end

  def allocate
    self.portfolios.map(&:allocate)
  end

  def corporated_from_position
    self.unallocate_positions.where("shares < ?", 0).select { |p| p.shares + self.allocate_shares(p.base_stock_id) == 0 }
  end

  def corporated_to_position
    self.unallocate_positions.select { |p| p.shares > 0 && self.allocate_shares(p.base_stock_id) == 0 }
  end

  def check_reconciled
    flag = true
    self.portfolios.each do |pf|
      flag = flag && pf.reconciled?
      break unless flag
    end
    flag
  end

  # 一月回报
  def basket_total_return
    count = self.baskets.normal.finished.computable.count
    avg = (self.baskets.normal.finished.computable).inject(0) {|sum, basket| sum + basket.one_month_return.to_f}
    count == 0 ? 0 : avg/count
  end

  # 总回报
  def basket_real_total_return
    count = self.baskets.normal.finished.computable.count
    avg = (self.baskets.normal.finished.computable).inject(0) {|sum, basket| sum + basket.total_return.to_f}
    count == 0 ? 0 : avg/count
  end

  # 今日回报
  def basket_change_percent
    count = self.baskets.normal.finished.computable.count
    avg = (self.baskets.normal.finished.computable).inject(0) {|sum, basket| sum + basket.change_percent.to_f}
    count == 0 ? 0 : avg/count
  end

  def profile_fluctuation
    if self.basket_fluctuation.to_f > 30
      120
    elsif self.basket_fluctuation.to_f > 20
      90
    elsif self.basket_fluctuation.to_f > 10
      60
    elsif self.basket_fluctuation.to_f > 0
      30
    else
      0
    end
  end

  def stocks_of_created_basket
    self.baskets.normal.finished.includes(:stocks).map(&:stocks).flatten
  end

  def stocks_of_followed
    Follow::Stock.followed_stocks_by(self.id).map(&:followable)
  end

  def stocks_of_followed_basket
    Basket.joins(:follows).where("follows.user_id = ?", self.id).includes(:stocks).map(&:stocks).flatten
  end

  def focus_stocks
    (stocks_of_created_basket + stocks_of_followed_basket + stocks_of_followed).uniq
  end

  def group_by_sector
    focus_stocks.group_by {|bs| bs.sector_code}
  end

  def focus_by_cache
    cache_key = "focus_by_cache_#{self.id}"
    $cache.fetch(cache_key, :expires_in => Time.now.seconds_until_end_of_day){ self.focus }
  end

  def focus_with_color
    focus_by_cache.to_a.first(3).map do |sector_name, percent|
      code = Sector::MAPPING.invert[sector_name]
      color = Sector::COLORS[code.to_s]
      [sector_name, percent, color]
    end
  end

  def focus
    group_num = group_by_sector.size
    h = {}
    group_by_sector.transform_values {|x| x.size}.sort_by {|k,v| v}.reverse.each_with_index do |a, i|
      h[a[0]] = i + 1 == group_num ? (100 - (h.values.sum || 0)).round : (a[1].to_f/focus_stocks.size * 100).round
    end
    h.transform_keys {|x| x.present? ? Sector::MAPPING[x.to_s] : "其他"}
  end

  def query_by_term(str)
    if str.present?
      users = self.followed_users.select("username").where("username like ?", "#{str.strip}%").limit(10)
    else
      users = self.followed_users.select("username").where.not(username: nil).limit(10)
    end
    users.map { |x| x.username }
  end

  def fluctuation
    baskets = self.baskets.normal.finished

    h = {}
    res = {}
    baskets.each do |b|
      h[b.id] = []
      1.upto(91).each do |i|
        h[b.id] << b.daily_return(ClosedDay.prev_workday_of(i, b.market)).to_f
      end
    end

    h.each do |k,v|
      a = []
      1.upto(v.size - 1) do |i|
        a << (v[i-1] == 0 ? 0 : (v[i] - v[i-1])/v[i-1].to_f)
      end
      res[k] = a
    end

    b = []
    0.upto(89) do |i|
      t = 0
      res.values.each do |c|
        t += c[i]
      end
      b << t/90.size.to_f
    end


    expectation = b.average

    variance = (b.inject(0.0) { |sum, v| sum + (v - expectation) ** 2 })/b.size.to_f

    deviation = variance ** 0.5

    baskets.any? { |b| b.is_cn? } ? deviation * (220 ** 0.5) : deviation * (250 * 0.5)
  end

  # 登录后对用户token表的处理
  def make_token(attrs={})
    raise Authentication::UserBlocked if blocked?
    if self.api_tokens.present?
      token = self.api_tokens.first
      token.refresh_self!(attrs)
    else
      self.create_api_tokens(attrs)
    end
  end

  def app_can_register?
    return false unless self.mobile
    $redis.getbit(APP_REGISTER_KEY, self.mobile).one?
  end

  def create_api_tokens(attrs={})
    token = ApiToken.new(attrs)
    token.user_id = self.id
    token.save
  end

  def return_token
    tokens = self.api_tokens
    tokens.first.try(:access_token)
  end

  def at_least_one_of_email_and_mobile
    if [self.mobile, self.email].all?(&:blank?)
      errors[:base] << "邮箱和手机号不能同时为空!"
    end
  end

  def app_login?
    token = self.api_tokens.try(:first)
    token.present? && !token.expired?
  end

  # app端对指定用户进行推送消息时调用
  # 不需要用户登录 is_login 设置为 false
  def jpush(content, is_login=true)
    if (is_login && app_login?) || !is_login
      $jp.send_by_alias(content, [self.id.to_s])
    end
  end

  # 0: 本人, 1: 互相关注, 2: 你关注了他, 3: 他关注了你, 4: 互相无关注
  def relation(user)
    if self.id == user.id
      0
    elsif user.friend?(self.id)
      1
    elsif user.followed_by?(self)
      2
    elsif self.followed_by?(user)
      3
    else
      4
    end
  end

  def do_reset_confirmation_token!
    EmailToken.find_by(email: self.email).reset_confirmation_token!
  end

  def self.search_by(term, limit = 10)
    self.where("username like ?", "#{term}%").limit(limit)
  end

  def contest_basket
    baskets.normal.contest.first
  end

  def active_account_ids
    trading_accounts.active.select(:id).map(&:id)
  end

  def has_finished_baskets?
    baskets.normal.finished.limit(1).present?
  end

  def pt?
    TradingAccountPT.find_by(user_id: id).present?
  end

  def best_basket_ret
    @best_basket_ret ||= baskets.normal.finished.order(total_return: :desc).first.try(:total_return) || 0
  end

  def max_win_rate
    @max_win_rate ||= trading_accounts.binded.map(&:win_rate).max || 0
  end

  def last_order_detail
    @last_order_detail ||= order_details.fill_finished.buyed.order("updated_at desc").first
  end

  def last_order_detail_data
    stock = BaseStock.find_by(id: last_order_detail.try(:base_stock_id))

    return nil unless stock.present?

    {
      stock_name: stock.c_name || stock.name,
      average_cost: last_order_detail.average_cost,
    }
  end

  include ProviderAccount
  # include UserVirtualStatistics

  include UserStatistics

  def binded_accounts
    TradingAccount.published.sort_by_login.binded.by_user(id)
  end

  def reset_following_baskets_count
    update(following_baskets_count: following_baskets.count)
  end

  def reset_following_stocks_count
    update(following_stocks_count: following_stocks.count)
  end

  def reset_baskets_count
    update(baskets_count: baskets.normal.finished.count)
  end

  # 粉丝
  def reset_following_users_count
    update(follows_count: follows.count)
  end

  # 关注
  def reset_followed_users_count
    update(followed_users_count: followings.count)
  end

  def joined_days
    (Date.today - created_at.to_date).to_i rescue 0
  end

  def add_favorite(record)
    target = StaticContent.get(record)
    target.followed_by_user?(id) ? false : target.follow_by_user(id)
  end

  def remove_favorite(record)
    target = StaticContent.get(record)
    target.followed_by_user?(id) ? target.unfollow_by_user(id) : false
  end

   # 实名认证
  def certification(id_no, real_name)
    return [false, "您已经进行过实名认证"] if self.user_certification.present?
    return [false, "该身份证已进行过实名认证"] if UserCertification.exists?(id_no: id_no)
    return [false, "认证超过#{UserCertification::MAX_TRY_COUNT}次，请明天再试"] if UserCertification.exceed_count?(id)

    uc = self.build_user_certification(id_no: id_no, real_name: real_name.strip)

    if uc.valid? && uc.third_party_certification
      return [uc.save, uc.errors.try(:messages)]
    else
      return [false, "未通过实名认证"]
    end
  end

  # 手机号是否存在
  def mobile_exists?
    mobile.present?
  end

  # 是否已进行实名认证
  def certification_exists?
    user_certification.present?
  end

  # 是否已经p2p开户
  def p2p_account_exists?
    p2p_account.present?
  end

  def p2p_account
    @p2p_account ||= trading_accounts.where(broker_id: Broker.p2p_broker.id).first
  end

  def p2p_token
    p2p_account.try(:broker_no)
  end

  # 总账户合计
  # 包括普通券商账户和理财宝账户
  # 账户净值和今日盈亏
  # UPDATE 理财宝账户不计算今日盈亏
  def total_accounts_amount
    trading_accounts = TradingAccount.by_user(id)
    normal = trading_accounts.published(false).map do |ta|
      { total_property: ta.total_property.to_f, today_profit: PositionArchive.today_profit(ta)[0].to_f }
    end
    p2p = { total_property: p2p_account.try(:total_property).to_f }

    {
      total_property: normal.sum{|n| n[:total_property] }.to_f + p2p[:total_property],
      today_profit: normal.sum{|n| n[:today_profit] }.to_f
    }
  end

  private

  def self.ransackable_scopes(auth_object = nil)
    %i(pc_app_channel)
  end
end
