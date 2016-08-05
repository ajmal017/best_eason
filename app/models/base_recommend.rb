class BaseRecommend < ActiveRecord::Base
  self.table_name = "recommends"

  attr_accessor :push_flag

  validates :original_url, presence: true, uniqueness: true, format: { with: /\A((?:http|https):\/\/w*)/i, message: "必须是网址" }, length: {minimum: 5, maximum: 255}, on: :create
  validates :category_id, presence: true

  belongs_to :staffer, class_name: "Admin::Staffer", foreign_key: :staffer_id

  before_save :set_category, if: :category_id_changed?
  before_save -> { self.push_flag = true }, if: -> { status_changed? && %w{pulling audited}.include?(status) }

  # 加入审批人时清除缓存
  after_save -> { @verifiers_list = nil }, if: -> { verifiers_changed? }
  after_save -> { update(status: "audited") }, if: -> { verifiers_changed? && full_verifiers? && status == "auditing" }

  # 推送url到后台进行抓取
  after_commit :push_url, if: ->{ push_flag }

  # 最大审批人数量
  VERIFIERS_COUNT = 1

  # 状态
  STATUS = {
    "pulling"   => "待抓取",
    "error"     => "抓取失败",
    "auditing"  => "待审核",
    "audited"   => "已审核",
    "published" => "已发布"
  }

  enum status: STATUS.keys.zip(STATUS.keys).to_h

  scope :un_published, -> { where.not status: ["published", "audited"] }
  scope :own, -> (staff) { where staffer_id: staffer.id  }

  def set_category
    self.category = category_name
  end

  def category_name
    category_id ? MD::Source::SpiderNewsCategory.where(category_id: category_id).limit(1).first.try(:name) : category
  end

  def status
    super || STATUS.keys.first
  end

  def verifiers
    super || ""
  end

  def status_zh
    STATUS[status]
  end

  def can_approve?(staffer)
    status == "auditing"
    # (staffer.admin || staffer.role.name == "高级编辑") && status == "auditing" && !full_verifiers? && !verifiers_list.pluck(:id).include?(staffer.id) 
  end

  def verifiers_list
    @verifiers_list ||= Admin::Staffer.where(id: verifiers.split(","))
  end

  def push_verifier(staffer)
    return false unless can_approve?(staffer)
    update(verifiers: (verifiers.split(",") << staffer.id).join(","))
  end

  def full_verifiers?
    verifiers_list.size >= VERIFIERS_COUNT
  end

  def push_url
    RestClient.api.tool.recommend(id)
  rescue
    $recommend_push_logger.error("recommend: #{id} 推送失败! [ #{Time.now} ]")
  end

  def self.can_visit?(staffer)
    true
    #staffer.admin || staffer.role.name == "高级编辑" || staffer.role.name == "网站编辑"
  end

  def self.only_visit_own?(staffer)
    false
    #!(staffer.role.name == "高级编辑") && !staffer.admin
  end

end
