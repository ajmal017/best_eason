module V1
  class P2p < Grape::API

    resource :p2p, desc: "理财投资相关" do

      # OVER
      add_desc "理财产品Banner"
      get :banners do
        banners = MobileP2pRecommend.banner_url_and_images.map do |id, infos|
          {
            type: infos[:type],
            url: infos[:image_url],
            link: infos[:url]
          }
        end
        present banners
      end

      # OVER
      add_desc "理财广告位"
      get :ads do
        present P2pAd.result_for_app
      end

      # OVER
      add_desc "理财产品开户"
      # 数据在service里提供无需接口输入
      # p2p_client_params "accounts", "create"
      post :open do
        authenticate!
        ta = current_user.p2p_account_exists? ? current_user.p2p_account : p2p_get(:user_open)
        present ta
      end

      # OVER
      add_desc "理财产品包列表"
      p2p_client_params "packages", "list"
      get :packages do
        present p2p_get(:packages)
      end

      # OVER
      add_desc "理财产品列表"
      p2p_client_params "products", "list"
      get :products do
        present p2p_get(:products)
      end

      # OVER
      add_desc "取消订单"
      p2p_client_params "payments", "cancel"
      delete "products/cancel_order" do
        authenticate!
        present p2p_get(:cancel_order)
      end

      # OVER
      add_desc "理财产品详情(基本数据)"
      p2p_client_params "products", "get"
      get "products/:id/detail" do
        present p2p_get(:product)
      end

      # OVER
      add_desc "理财产品详情(投资记录,可分页)"
      p2p_client_params "products", "buyers"
      get "products/:id/invest_records" do
        present p2p_get(:product_buyers)
      end

      # OVER
      add_desc "用户已购买的理财产品详情"
      p2p_client_params "products", "detail"
      get "products/:id/buyed" do
        authenticate!
        verify_p2p_account!
        present p2p_get(:product_detail)
      end

      # OVER
      add_desc "购买理财产品"
      p2p_client_params "products", "buy"
      post "products/:id" do
        authenticate!
        verify_p2p_account!
        present p2p_get(:product_buy)
      end

      # OVER
      add_desc "用户购买的理财产品列表"
      p2p_client_params "orders", "products"
      get "account/products" do
        authenticate!
        verify_p2p_account!
        present p2p_get(:current_user_products)
      end

      # OVER
      add_desc "用户理财宝帐号"
      p2p_client_params "orders", "profile"
      get :account do
        authenticate!
        result = {}
        result[:account_exist] = current_user.p2p_account_exists?
        present (current_user.p2p_account_exists? ? result.merge(current_user.try(:p2p_account).try(:format_json)) : result)
      end

      # OVER
      add_desc "用户交易记录"
      p2p_client_params "orders", "orders"
      get "account/trading_records" do
        authenticate!
        verify_p2p_account!
        present p2p_get(:user_orders)
      end

      # OVER
      add_desc "用户每日收益"
      p2p_client_params "orders", "daily_interest"
      get "account/daily_interest" do
        authenticate!
        verify_p2p_account!
        present p2p_get(:user_daily_interest)
      end

      # OVER
      add_desc "银行列表"
      get :banks do
        present p2p_get(:banks)
      end

      # OVER
      add_desc "某用户持有的银行卡"
      get "banks/cards" do
        authenticate!
        verify_p2p_account!
        present p2p_get(:bankcards)
      end

      # OVER
      add_desc "确认短信验证码"
      p2p_client_params "payments", "confirm_validation_code"
      post "banks/confirm_validation_code" do
        authenticate!
        present p2p_get(:confirm_validation_code)
      end

      # OVER
      add_desc "重新发送短信验证码"
      p2p_client_params "payments", "resend_sms"
      post "banks/resend_sms" do
        authenticate!
        present p2p_get(:resend_sms)
      end

    end

  end
end

