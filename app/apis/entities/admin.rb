module Entities
  class Staffer < ::Entities::Base
    expose :id, documentation: {type: Integer, desc: "id"}
    expose :username, documentation: {type: String, desc: "用户名"}
    expose :fullname, documentation: {type: String, desc: "名称"}
    expose :admin, documentation: {type: Grape::API::Boolean, desc: "是否为超级管理员"}
    expose :role_id, documentation: {type: Integer, desc: "角色id"}
    expose :access_token, documentation: {type: String, desc: "管理员token"}, if: {type: :token}

    private
    def access_token
      tokens = object.api_staffer_tokens
      tokens.first.access_token unless tokens.empty?
    end
  end
end
