class PtApplication < ActiveRecord::Base
  attr_accessor :captcha

  belongs_to :user

  validates_presence_of :q1, :q2, :q3, :q4, :q5, :q6, :q7, :q8, :q9, :mobile

  validates_presence_of :name, :id_no, :bank_name, :card_no, if: -> {approved? && (name_changed? || id_no_changed? || bank_name_changed? || card_no_changed?)}

  SUCCESS_MSG = <<-HTML
尊敬的财说用户您好，

您已通过财说实盘大赛报名审核，请您到大赛报名专题继续补充个人详细信息，预祝您在本次比赛中取得好成绩！
点击以下链接继续补充信息：<a href="https://www.caishuo.com/events/shipandasai/new">https://www.caishuo.com/events/shipandasai</a>

财说
HTML

  FAILED_MSG = <<-HTML
尊敬的财说用户您好，

很遗憾的通知您，您所提供的资料不符合本次财说实盘大赛的要求,未通过审核。
感谢您对财说的支持，希望您继续关注财说下一次比赛。或者,在本次比赛过程中来观摩高手的对决也不错哦～
  看高手对决点这里：<a href="https://www.caishuo.com/events/shipandasai">https://www.caishuo.com/events/shipandasai</a>

财说
  HTML

  SUCCESS_SMS = "财说用户您好，您已通过财说实盘大赛报名审核，请您登录财说官网收取私信并继续补充个人详细信息，预祝您在本次比赛中取得好成绩！"
  FAILED_SMS = "财说用户您好，很遗憾的通知您，您所提供的资料不符合本次财说实盘大赛的要求，未通过审核。感谢您对财说的支持，希望您继续关注财说下一次比赛。或者，在本次比赛过程中来观摩高手的对决也不错哦～"

  
  WELCOME_MSG = <<-HTML
财说首届实盘炒股大赛开始啦。你炒股，我出钱，收益归你，风险我抗。
报名通过就送3万实盘资金，大赛冠军赢200万大奖，70%收益拿回家。
炒股高手速来报名<a href="https://www.caishuo.com/events/shipandasai">https://www.caishuo.com/events/shipandasai</a>
  HTML

  STATUS_NAMES = %w{申请中 已通过 未通过}
  enum status: [ :init, :approved, :rejected ]
  before_save do
    self.q4 = q4_before_type_cast.is_a?(String) ? q4_before_type_cast : q4_before_type_cast.join(',')
  end
  def q4
    q4_before_type_cast.is_a?(String) ? q4_before_type_cast.split(',').map(&:to_i) : q4_before_type_cast
  end

  def status_name
    STATUS_NAMES[attributes['status'].to_i]
  end

  def notice
    send_sms
    send_message
    update(noticed: true)
  end

  def send_sms
    begin
      Sms.send_sms(mobile, sms)
    rescue => e
      Rails.logger.error("SMS Failed: #{mobile}, id: #{id}")
    end
  end

  def send_message
    begin
      Message.add(Setting.auto_followed_user_id, user_id, message)
    rescue => e
      Rails.logger.error("MESSAGE Failed: #{mobile}, id: #{id}")
    end
  end

  def sms
    approved? ? SUCCESS_SMS : FAILED_SMS
  end

  def message
    approved? ? SUCCESS_MSG : FAILED_MSG
  end

  def notice_failed
    "失败"
  end

  def self.send_welcome_msg
    sender_id = Setting.auto_followed_user_id
    User.where("id > 2013").pluck(:id).each do |user_id|
      puts user_id
      next if user_id == sender_id
      begin
        Message.add(sender_id, user_id, WELCOME_MSG)
      rescue => e
        Rails.logger.error("MESSAGE Failed: #{mobile}, id: #{id}")
      end

    end
  end


end
