class BasketAudit < ActiveRecord::Base
  belongs_to :basket
  belongs_to :admin, class_name: Admin::Staffer, foreign_key: :admin_id

  # 审核状态
  STATE = {auditing: 0, pass: 1, not_pass: 2}
  STATE_DESC = {"审核中" => 0, "已通过" => 1, "未通过" => 2}

  scope :auditing, -> { where(state: STATE[:auditing]) }

  before_save :send_audit_notification

  def auditing?
    self.state == STATE[:auditing]
  end

  def not_pass?
    self.state == STATE[:not_pass]
  end

  def pass!
    self.update(state: STATE[:pass])
  end

  def not_pass!(unpass_reason)
    self.update(state: STATE[:not_pass], unpass_reason: unpass_reason)
  end

  def state_desc
    STATE_DESC.invert[self.state]
  end

  private
  # 发送主题审核通知
  def send_audit_notification
    if state_was == STATE[:auditing] && state == STATE[:pass] 
      Notification::System.create(user_id: self.basket.author_id, mentionable: self.basket, basket_audit_result: 'pass')
    elsif state_was == STATE[:auditing] && state == STATE[:not_pass]
      Notification::System.create(user_id: self.basket.author_id, mentionable: self.basket, basket_audit_result: 'not_pass', unpass_reason: self.unpass_reason)
    end
  end
end
