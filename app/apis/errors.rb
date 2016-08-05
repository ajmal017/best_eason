module APIErrors
  extend ActiveSupport::Concern

  def self.included(klass)
    klass.send(:include_errors)
  end

  VeriftyFail       = Class.new StandardError
  AuthenticateFail  = Class.new StandardError
  NoVisitPermission = Class.new StandardError
  NoGetAuthenticate = Class.new StandardError
  AccountNotlogin   = Class.new StandardError
  VersionOldError   = Class.new StandardError
  class P2pResponseError < StandardError
    attr_accessor :response
    def initialize(message, response)
      super message
      @response = response
    end
  end

  module ClassMethods

    def include_errors
      rescue_from :all do |e|
        Rails.logger.error "#{e.message}\n\n#{e.backtrace.join("\n")}"
        out_error(code: 2001, msg: e.message)
      end

      rescue_from VeriftyFail do |e|
        out_error(code: 1001, msg: e.message || "失败")
      end

      rescue_from NoVisitPermission do |e|
        out_error(code: 1002, msg: "无访问权限")
      end

      rescue_from AuthenticateFail do |e|
        out_error(code: 1003, msg: "没有访问权限，请重新登录")
      end

      rescue_from ActiveRecord::RecordNotFound, Mongoid::Errors::DocumentNotFound do |e|
        out_error(code: 1004, msg: "没有找到相关数据")
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        out_error(code: 1005, msg: e.message)
      end

      rescue_from Grape::Exceptions::ValidationErrors do |e|
        out_error(code: 1006, msg: e.message || "输入内容格式有误")
      end

      rescue_from NoGetAuthenticate do |e|
        out_error(code: 1007, msg: "没有访问权限，请重新登录")
      end

      rescue_from AccountNotlogin do |e|
        out_error(code: 1008, msg: "请登录券商账号")
      end

      rescue_from VersionOldError do |e|
        out_error(code: 1009, msg: "您的应用版本过旧，请更新最新版本")
      end

      rescue_from ::Authentication::UserBlocked do |e|
        out_error(code: 1010, msg: "您的账号已被锁定，请联系客服！")
      end

      rescue_from P2pResponseError do |e|
        out_error(code: e.response.err_code, msg: e.response.err_msg || "未知系统错误")
      end

    end

  end
end
