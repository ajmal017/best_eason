module V1
  module Admin
    class Users < Grape::API

      namespace :admin, desc: "管理后台相关" do

        resource :users do
        end

        add_desc "管理员登录"
        params do
          requires :username, type: String, desc: "用户名"
          requires :password, type: String, desc: "密码"
        end
        post :login do
          raise APIErrors::VeriftyFail, "登录失败，用户名或密码不正确" unless @staffer = ::Admin::Staffer.check_login?(params[:username], params[:password])

          @staffer.make_token(sn_code: sn_code)
          present @staffer, with: ::Entities::Staffer, type: :token
        end

        add_desc "管理员登出"
        delete :logout do
          staffer_authenticate!
          current_staffer.api_staffer_tokens.first.update(expires_at: Time.now - 1.days)
        end

      end

    end
  end
end
