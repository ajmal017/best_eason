class Grape::API
  class << self
    # 文档中需要填写header信息时使用
    def add_desc(desc, options={})
      desc "#{desc}", {
        headers: {
          "Authorization" => {
            description: "用户token",
            required: false
          },
          "X-SN-Code" => {
            description: "设备唯一识别码",
            required: false
          },
          "X-Client-Key" => {
            description: "访问权限",
            required: false
          },
          "X-Client-Version" => {
            description: "应用版本",
            required: false
          }
        }
      }.merge(options)
    end

    def p2p_client_params(namespace, method)
      params do
        P2pService.client_doc(namespace, method).each do |k, v|
          next if %i[user_terminal_info user_terminal_ip].include? k
          send(v[:type], k, { type: v[:klass] == "bool" ? Grape::API::Boolean : String }.merge!(v.slice(:values, :default, :desc)))
        end
      end
    end

  end
end

module Grape::Middleware
  class Error
    # 将默认错误返回状态码改为200
    def out_error(message={})
      error = {
        message: message,
        status: 200
      }
      error_response(error)
    end
  end
end
