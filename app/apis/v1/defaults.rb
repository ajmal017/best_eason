Dir["#{Rails.root}/app/apis/*.rb", "#{Rails.root}/app/apis/entities/*.rb"].each {|p| require p }

module V1
  module Defaults
    extend ActiveSupport::Concern
    included do
      prefix          "api"
      version         'v1', using: :path
      format          :json
      content_type    :json, 'application/json;charset=UTF-8'
      default_format  :json
      formatter       :json, BodyFormatter
      error_formatter :json, ErrorFormatter
      helpers         APIHelpers

      include         APIErrors
      # 调用接口时验证api_key
      before do
        I18n.locale = 'zh-CN'

        unless request.path =~ /\/api-doc/
          raise APIErrors::NoVisitPermission if headers["X-Client-Key"] != ::Setting.api_key

          # 额外统计相关工作
          extend_callback

          # 强制更新版本
          force_update!

        end
      end
    end
  end
end
