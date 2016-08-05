class AdminLog < ActiveRecord::Base
  validates :staffer_id, presence: true
  validates :content, presence: true

  belongs_to :staffer, class_name: "Admin::Staffer"

  LOG_TYPE = { 'Trading' => '交易', 'User' => '用户', 'Basket' => '组合', 'Article' => '内容' }

  scope :one_month_ago, -> { where("created_at < ?", 1.month.ago) }

  def cn_log_type
    LOG_TYPE[self.log_type]
  end
end
