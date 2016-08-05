class PushLog < ActiveRecord::Base
  attr_accessor :password

  validates :push_key, presence: true, unless: -> { push_type == "broadcast"  }
  validates :content, presence: true, custom_length: {min: 1, max: 200, message: "长度不合法"}

  STATUS = {
    "ready" => "准备中",
    "success" => "发送成功",
    "failed" => "发送失败",
  }

  PUSH_TYPE = {
    "alias" => "别名",
    "broadcast" => "群发"
  }

  enum status: STATUS.keys

  scope :by_staffer, -> (staffer_id) { where staffer_id: staffer_id }
  scope :desc, -> { order id: :desc }

  belongs_to :staffer, class_name: "Admin::Staffer", foreign_key: :staffer_id

  validate :check_password

  def push_type_zh
    PUSH_TYPE[push_type]
  end

  def status_zh
    STATUS[status]
  end

  def push_all?
    push_type == "broadcast"
  end

  before_create :push

  def push
    state, result =
      case push_type
      when "alias"
        $jp.send_by_alias(push_key, alert: content, type: mentionable_type, id: mentionable_id)
      when "broadcast"
        $jp.send_broadcast(alert: content, type: mentionable_type, id: mentionable_id)
      end

    #JpushPublisher.publish({type: push_type, alias: push_key, content: content})

    callback(state, result)
  end

  # 回调修改状态
  # state: true/false 发送成功或失败
  # result: push response 信息
  def callback(state, result)
    status = state ? "success" : "failed"
    self.status = status
    self.result = result.to_json
  end

  def receiver=(receiver)
    if push_type.blank?
      if receiver.blank?
        self.push_type = "broadcast"
      else
        self.push_type = "alias"
        self.push_key = receiver if push_key.blank?
      end
    end
  end

  def receivers
    if push_all?
      "所有用户"
    else
      User.where("id in (?)", push_key).pluck(:username).join(", ")
    end
  end

  private
  def check_password
    if push_all?
      self.errors.add(:password, :invalid) if password != Setting.jpush.push_password
    end
  end

end
