class Jpush

  require 'jpush'

  def initialize(app_key, master_secret)
    @client = JPush::JPushClient.new(app_key, master_secret)
  end

  def send_notification(notification, opts={})

    _opts = {}
    _opts[:platform] = opts[:platform].present? ? JPush::Platform.build(opts[:platform]) : JPush::Platform.all
    _opts[:audience] = opts[:audience].present? ? JPush::Audience.build(opts[:audience]) : JPush::Audience.all

    notification = [notification].flatten.reduce({}) do |n,m|
      next unless m.is_a? Jp::BaseMsg
      if m.is_a? Jp::AndroidMsg
        n.merge!(android: JPush::AndroidNotification.build(m.to_msg))
      elsif m.is_a? Jp::IOSMsg
        n.merge!(ios: JPush::IOSNotification.build(m.to_msg))
      end
      n
    end
    _opts[:notification] = JPush::Notification.build notification
    _opts[:options] = JPush::Options.build(apns_production: Rails.env.production?, time_to_live: 7200)

    payload = JPush::PushPayload.build _opts

    begin
      result = @client.sendPush(payload)
      state = true
      $jpush_logger.info("request: #{payload.to_json}, response: #{result.to_json}")
    rescue JPush::ApiConnectionException=>e
      state = false
      wrapper = e.res_wrapper
      result = {code: wrapper.code.to_s, msg: wrapper.error.to_s}
      $jpush_logger.error("[request: #{payload.to_json}] Code: #{wrapper.code.to_s}, Msg: #{wrapper.error.to_s}, Info: #{_opts.to_s}")
    ensure
      return [state, result]
    end
  end

  def device(opts={})
    [Jp::IOSMsg.new(opts), Jp::AndroidMsg.new(opts)]
  end

  #广播
  def send_broadcast(opts={})
    send_notification(device(opts))
  end

  #通过tag推送
  def send_by_tag(tag=[], opts={}) #数组的元素是string
    tag = [tag].flatten
    send_notification(device(opts), audience: {tag: tag})
  end

  #多个标签求and筛选后推送
  def send_by_tag_and(tag=[], opts={}) #数组的元素是string
    tag = [tag].flatten
    send_notification(device(opts), audience: {tag_and: tag})
  end

  #通过别名推送
  def send_by_alias(user_alias=[], opts={}) #数组的元素是string
    valid_user_alias = ApiToken.where(user_id: user_alias).pluck(:user_id).map(&:to_s)
    return [false, "用户没有使用过app"] if valid_user_alias.blank?

    send_notification(device(opts), audience: {_alias: valid_user_alias})
  end

end

module Jp
  class BaseMsg
    def initialize(alert:, type: nil, id: nil, title: "财说")
      @id    = id
      @type  = type
      @alert = alert
      @title = title
    end

    def extras
      { type: @type, value: @id }
    end

    def to_msg
      { alert: @alert, extras: extras }
    end
  end

  class AndroidMsg < BaseMsg
    def to_msg
      super.merge({ title: @title, builder_id: 1 })
    end
  end

  class IOSMsg < BaseMsg
    def to_msg
      super.merge({ sound: "", badge: 0 })
    end
  end
end

$jp = Jpush.new(*Setting.jpush.except("push_password").values.flatten)
