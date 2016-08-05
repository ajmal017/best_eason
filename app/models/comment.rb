require 'elasticsearch/model'
class Comment < ActiveRecord::Base
  include Likeable
  include Mentionable
  include Notifyable
  include AccessDbRelate
  include Elasticsearch::Model

  include Feedable

  after_create  { |document| document.__elasticsearch__.index_document rescue true }
  after_update  { |document| document.__elasticsearch__.update_document rescue true }
  after_destroy { |document| document.__elasticsearch__.update_document rescue true }

  validates :user_id, presence: true
  # text为原始内容
  validates :text, presence: true, sensitive: true
  # 渲染html后内容
  validates :body, length: {maximum: 50000, too_long: "内容长度超过限制"}, on: :create
  
  # 评论者
  belongs_to :commenter, class_name: 'User', foreign_key: :user_id
  alias :user :commenter
  
  # 最顶级被回复的对象 比如basket/topic/stock
  belongs_to :top_commentable, polymorphic: true, counter_cache: :comments_count
  
  # 最顶级被回复的评论
  belongs_to :root_replyed, class_name: :Comment, foreign_key: :root_replyed_id

  scope :sort_desc, -> { order(id: :desc) }
  scope :deleted, -> { where deleted: true }
  scope :undeleted, -> { where deleted: false }
  scope :top, -> { where commentable_ids: nil }
  scope :created_gte, ->(time) { where("created_at >= ?", time) }
  scope :id_lt, -> (id) { where("id < ?", id) if id > 0 }

  PER_PAGE = 20

  after_destroy :reset_comments_count #, :delete_notification

  def destroy
    run_callbacks(:destroy) do
      self.update(deleted: true) if persisted?
      @destroyed = true
    end
    Resque.enqueue(DeleteCommentWorker, id)
    freeze
  end

  def restore_destroy
    self.update(deleted: false)
    self.__elasticsearch__.index_document rescue true
  end

  def likes_count
    read_attribute(:likes_count).to_i
  end

  def comments_count
    read_attribute(:comments_count).to_i
  end

  def format_err_msg
    errors[:text].try(:first) || errors[:body].try(:first) || "评论发布失败"
  end

  # 评论删除后显示评论已被删除
  def content
    #deleted ? "抱歉，此评论已被作者删除。" : super
    super
  end

  # 评论html的内容的缩写
  def safe_content
    Sanitize.clean(content, SanitizeRules::BASIC).html_safe
  end
  
  # 评论内容html
  def safe_body
    Sanitize.clean(body.to_s, SanitizeRules::BASIC).html_safe
  end

  def result_content
    deleted ? "抱歉，评论已删除" : text 
  end
  
  def commented_by?(user_id)
    user_id.present? && self.user_id == user_id
  end

  # 根据被回复节点的commentable_ids计算出来新的子节点的值
  def child_commentable_ids
    commentable_ids.to_s + id.to_s + ","
  end

  def ary_commentable_ids
    commentable_ids.split(",").map(&:to_i) rescue []
  end

  # 被直接回复的评论
  def direct_replyed
    @direct_replyed ||= self.class.find_by(id: ary_commentable_ids.last)
  end

  after_create :increment_root_replyed_counter, if: "self.commentable_ids.present?"
  def increment_root_replyed_counter
    root_replyed.increment!(:comments_count)
  end

  def commenter_link(card=true,prefix=" //",suffix=":")
    ApplicationController.helpers.link_to_user(self.commenter, inner: (prefix + commenter.username + suffix), card: card)
  end

  def content_with_commenter_link
    [commenter_link, safe_body].join(" ")
  end

  def message
    return safe_body unless top_replyed.present?

    ary_commentable_ids[1..-1].inject(safe_body) do |msg, commenting_id|
      msg += self.class.find(commenting_id).content_with_commenter_link.html_safe
    end
  end

  def block
    return nil unless top_replyed.present? 
    
    [top_replyed.commenter_link(true, ''), top_replyed.safe_content].join(" ")
  end

  def plain_json
    data = {
      id: id, 
      userid: user_id,
      username: commenter.username,
      avator: commenter.avatar_url(:normal), 
      date: created_at.try(:to_s, :short) + "|" + created_at.try(:iso8601), 
      voted: likes_count, 
      ischat: plain_ischat, 
      iserased: plain_iserased, 
      message: full_body, 
      status: 0
    }
    
    # 如果一级评论为空或者被删除
    (root_replyed.blank? || root_replyed.deleted?) ? data : data.merge(block: root_replyed_body)
  end

  # 评论创建成功
  def json_with(user_id)
    attrs = {
      isowner: plain_isowner(user_id),
      isvoted: plain_isvoted(user_id),
      totalNumber: top_commentable.reload.comments_count
    }

    plain_json.merge(attrs)
  end

  # 是否可以查看对话(主贴没有删除，并且有回复)
  def is_chat?
    one_level_reply.comments_count > 0
  end

  # 主贴
  def one_level_reply
    @one_level_reply ||= (root_replyed || self)
  end

  #1可以查看对话0不可以
  def plain_ischat
    format_boolean is_chat?
  end

  #1主贴已经删除0没有删除
  def plain_iserased
    format_boolean is_erased?
  end

  def is_erased?
    one_level_reply.deleted?
  end

  def plain_isvoted(user_id)
    format_boolean likes.exists?(user_id: user_id)
  end

  def plain_isowner(user_id)
    format_boolean self.user_id == user_id
  end

  def format_boolean(value)
    value ? 1 : 0
  end

  def self.list_json(comments, user_id)
    voted_ids = voted_ids_for(user_id, comments.map(&:id))
    
    comments.map do |comment|
      isvoted, isowner = (voted_ids.include?(comment.id) ? 1 : 0), comment.plain_isowner(user_id)
      comment.plain_json.merge(isvoted: isvoted, isowner: isowner)
    end
  end

  def self.voted_ids_for(user_id, likeable_ids)
    Like.where(user_id: user_id, likeable_id: likeable_ids.uniq, likeable_type: 'Comment').map(&:likeable_id)
  end

  alias_method :top_comments, :root_replyed

  def undeleted_comments
    root_replyed_or_self.child_comments
  end

  def root_replyed_or_self
    root_replyed_id.nil? ? self : root_replyed
  end

  def child_comments
    self.class.where("commentable_ids like ?", "#{self.id},%").undeleted.order(id: :desc)
  end

  def lower_comments
    self.class.where("commentable_ids like ?", "%#{self.id},").undeleted.order(id: :desc)
  end

  def self.talk_json(comment, user_id)
    comment.one_level_reply.child_comments.push(comment.one_level_reply).map do |comment|
      comment.plain_json.merge(isvoted: comment.plain_isvoted(user_id), isowner: comment.plain_isowner(user_id))
    end
  end

  # 内容截取100个字符
  before_validation :set_content_and_body, if: "self.text_changed?"
  def set_content_and_body
    truncated_text = Caishuo::Utils::Text.truncate_body(self.text)
    self.content = Caishuo::Utils::Text.auto_link_text(truncated_text)
    self.body = Caishuo::Utils::Text.auto_link_text(self.text)
  end

  # 设置一级评论
  before_save :set_root_replyed, :set_full_message, :set_root_replyed_body, :set_mobile_body, if: "self.text_changed?"
  def set_root_replyed
    self.root_replyed_id = ary_commentable_ids.first
  end

  def set_full_message
    if root_replyed_id
      self.full_body = Comment.where(id: ary_commentable_ids).order(:id)[1..-1].reverse.inject(safe_body) do |msg, commentable|
        msg += commentable.content_with_commenter_link.html_safe
      end
    else
      self.full_body = safe_body
    end
  end

  def set_mobile_body
    if root_replyed_id
      self.mobile_body = Comment.where(id: ary_commentable_ids).order(:id)[1..-1].reverse.inject(text) do |msg, commentable|
        msg += " //#{commentable.commenter.try(:username)}: #{commentable.result_content}"
      end
    end
  end

  def set_root_replyed_body
    if root_replyed_id
      self.root_replyed_body = [root_replyed.commenter_link(true, ''), root_replyed.safe_content] * " "
    end
  end

  # 创建一级评论
  def self.add(user_id, content, top_commentable)
    if top_commentable.is_a?(MD::Data::SpiderNews)
      top_commentable = StaticContent.get(top_commentable)
    end
    create(user_id: user_id, text: content, top_commentable: top_commentable)
  end

  # 创建评论回复
  def self.reply(user_id, content, comment)
    create({
      user_id: user_id,
      text: content,
      top_commentable: comment.top_commentable,
      commentable_ids: comment.child_commentable_ids
    })
  end

  def feed_type
    case top_commentable_type.to_s
    when "Article"
      :article_comment
    when "BaseStock"
      :stock_comment
    when "Basket"
      :basket_comment
    when "Contest"
      :contest_comment
    when "Topic"
      :topic_comment
    when "StaticContent"
      top_commentable.comment_feed_type
    end
  end

  def final_mobile_content
    root_replyed_id.nil? ? result_content : mobile_body
  end

  # 创建评论 (分发创建类型)
  def self.make(user_id, content, commentable)
    params = [user_id, content, commentable]
    method = commentable.is_a?(Comment) ? "reply" : "add"
    send(method, *params)
  end
  
  def final_top_commentable_id
    case top_commentable_type.to_s
    when "StaticContent"
      top_commentable.sourceable_id
    else
      top_commentable_id
    end
  end

  def final_path
    case top_commentable_type.to_s
    when "StaticContent"
      top_commentable.final_path
    when "BaseStock"
      "stocks"
    else
      top_commentable_type.try(:tableize)
    end
  end

  def top_commentable_url
    "/#{final_path}/#{final_top_commentable_id}#Comments"
  end

  def source_info
    "#{self.try(:commenter).try(:username)}：#{self.text}"
  end

  def delete_relative_records
    return unless deleted
    delete_notification
    delete_feeds
  end
  
  private
  
  # 创建@通知
  def create_notification_mention
    noticer = noticeable.respond_to?(:user_id) ? noticeable.user_id : nil

    self.mentioned_user_ids.each do |mention_user_id|
      # 如果被评论对象的作者和@的人重复,则不再发送@通知
      next if mention_user_id == noticer

      Notification::Mention.create({
        triggered_user_id: self.user_id, 
        user_id: mention_user_id, 
        mentionable: direct_replyed || top_commentable, 
        originable: self, 
        targetable: top_commentable
      }) 
    end
  end
  
  # 评论通知
  def send_notification
    if noticeable.respond_to?(:user_id)
      Notification::Comment.add(noticeable.user_id, self.user_id, noticeable, self)
    end
  end

  def noticeable
    @noticeable ||= (direct_replyed || top_commentable)
  end

  def delete_notification
    # 评论通知
    Notification::Comment.where(originable_id: self.id, originable_type: self.class.name).destroy_all
    # 赞通知
    Notification::Like.where(mentionable_id: self.id, mentionable_type: self.class.name).destroy_all
  end

  def reset_comments_count
    self.top_commentable.update(comments_count: top_commentable.comments.where(deleted: false).count) if top_commentable
    if root_replyed.present?
      root_replyed.update(comments_count: root_replyed.child_comments.count)
    end
  end

  def delete_feeds
    MD::Feed::Comment.where(source_id: self.id).delete_all
    MD::Feed::Comment.where("items._id" => self.id).each do |feed_c|
      feed_c.items.where("_id" => self.id).first.update(ext_data: {deleted: true})
    end
    MD::Feed::Like.where(feed_type: :comment_like, "items._id" => self.id).delete_all
  end

end
