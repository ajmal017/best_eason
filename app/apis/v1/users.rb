module V1
  class Users < Grape::API

    resource :users, desc: "用户相关" do

      add_desc "当前登录用户id查询"
      get :me do
        authenticate!
        present ({ user: {uid: current_user.id} })
      end

      add_desc "第三方帐号登录或绑定"
      params do
        requires :provider, type: String, desc: "第三方类型", values: ::User::PROVIDER
        requires :provider_id, type: String, desc: "第三方id"
        optional :access_token, type: String, desc: "access_token"
        optional :nick_name, type: String, desc: "昵称"
        optional :avatar, type: String, desc: "头像"
        optional :channel_code, type: String, desc: "渠道号"
      end
      post :provider do
        @is_new = false

        # 验证access_token
        if params[:access_token].present?
          raise ::APIErrors::VeriftyFail, "access_token验证未通过" unless User.verify_access_token(params[:provider], params[:provider_id], params[:access_token])
        end

        user_info = {nickname: params[:nick_name], image: params[:avatar], headimgurl: params[:avatar]}
        if current_user.present?
          @result = User.bind_provider_user(current_user, params[:provider], params[:provider_id], user_info)
          raise APIErrors::VeriftyFail, @result[:msg] if @result[:error]
        else
          @user, @is_new = User.make_provider_user(params[:provider], params[:provider_id], user_info)

          @user.is_new = @is_new
          @user.update(channel_code: params[:channel_code]) if @is_new && params[:channel_code].present?

          # 设置登录
          @user.make_token(sn_code: sn_code)
        end

        present @user, with: ::Entities::User, type: :token, current_user: @user
      end

      add_desc "绑定或更换手机号（调用此接口前，请先调用发送验证码接口）"
      params do
        requires :mobile, type: String, desc: "手机号", regexp: /^((\+86)|(86))?\d{11}$/
        requires :code, type: String, desc: "验证码"
        optional :password, type: String, desc: "密码"
      end
      post :phone do
        authenticate!
        #raise APIErrors::VeriftyFail, "已绑定手机号!" if current_user.mobile.present?
        raise APIErrors::VeriftyFail, "手机号已绑定!" if ::User.find_by(mobile: params[:mobile]).present?
        raise APIErrors::VeriftyFail, Sms.error_info(params[:mobile]) unless Sms.verifty(params[:mobile], params[:code])
        ::User.transaction do
          current_user.update!(mobile: params[:mobile])
          current_user.reset_password_with_validate!(params[:password], params[:password]) if params[:password].present?
        end
      end

      add_desc "解绑手机号（调用此接口前，请先调用发送验证码接口）"
      params do
        requires :code, type: String, desc: "验证码"
      end
      delete :phone do
        authenticate!
        raise APIErrors::VeriftyFail, "不能解绑手机号!" unless current_user.email.present?
        raise APIErrors::VeriftyFail, Sms.error_info(current_user.mobile) unless Sms.verifty(current_user.mobile, params[:code])
        current_user.update!(mobile: nil)
      end

      add_desc "解绑第三方帐号"
      params do
        requires :provider, type: String, desc: "第三方类型", values: ::User::PROVIDER
      end
      delete :provider do
        authenticate!
        raise APIErrors::VeriftyFail, "不能解绑该第三方帐号!" unless current_user.can_remove_bind?
        raise APIErrors::VeriftyFail, "还没有绑定该类第三方帐号!" unless current_user.send("#{params[:provider]}_provider_actived").present?
        current_user.send("#{params[:provider]}_provider_actived").destroy
      end

      add_desc "用户实名认证"
      params do
        requires :id_no, type: String, desc: "身份证号"
        requires :real_name, type: String, desc: "真实姓名"
      end
      post :certification do
        authenticate!
        bool, msg = current_user.certification(params[:id_no], params[:real_name])
        raise APIErrors::VeriftyFail, msg unless bool
        bool
      end

      add_desc "上传通讯录接口, REQUEST:  [13500000000, 13800000000...]
                                RESPONSE: [21, 0...] (为0则表示不匹配， 不为0为查询到的user_id)"
      params do
        requires :mobiles, type: String, desc: "json格式的mobiles数组 [13500000000, 13800000000...]"
      end
      post :phone_books do
        authenticate!

        result =
          begin

            mobiles =  JSON.parse(params[:mobiles])

            mobiles.map do |mobile|
              if mobile =~ /^((\+86)|(86))?\d{11}$/ && (user = User.find_by(mobile: mobile.gsub(/^((\+86)|(86))/, "")))
                user.id
              else
                0
              end
            end

          end

        present result

      end

      add_desc "短信验证码发送接口（测试环境发送的验证码默认为1234, 验证时有#{Sms::ALLOW_WRONG_COUNT}次试错机会）"
      params do
        requires :mobile, type: String, desc: "手机号", regexp: /^((\+86)|(86))?\d{11}$/
      end
      post :verification_code do
        raise APIErrors::VeriftyFail, "短信验证码发送失败!" unless Sms.send(params[:mobile])
      end

      add_desc "验证手机号可用性接口"
      params do
        requires :mobile, type: String, desc: "手机号", regexp: /^((\+86)|(86))?\d{11}$/
      end
      get :verify_mobile do
        raise APIErrors::VeriftyFail, "手机号已使用!" if ::User.find_by(mobile: params[:mobile]).present?
      end

      # 需先验证手机验证码是否正确，然后完成注册, 注册完成后自动生成token完成登录
      add_desc "用户注册接口", entity: ::Entities::User
      params do
        requires :mobile, type: String, desc: "手机号", regexp: /^((\+86)|(86))?\d{11}$/
        requires :password, type: String, desc: "密码"
        requires :code, type: String, desc: "验证码"
        optional :channel_code, type: String, desc: "渠道号"
      end
      post do
        mobile, password, code, channel_code = params[:mobile], params[:password], params[:code], params[:channel_code]
        raise APIErrors::VeriftyFail, "手机号已使用!" if ::User.find_by(mobile: mobile)
        raise APIErrors::VeriftyFail, Sms.error_info(mobile) unless Sms.verifty(mobile, code)

        @user = ::User.new(mobile: mobile, password: password)
        @user.source = "app" # 设置来源为app
        @user.channel_code = channel_code if channel_code.present?

        raise APIErrors::VeriftyFail, "注册失败!" unless @user.save

        # 注册成功，生成token记录
        @user.make_token(sn_code: sn_code)

        present @user, with: ::Entities::User, type: :token, current_user: @user
      end

      add_desc "修改密码接口"
      params do
        requires :old_password, type: String, desc: "原密码"
        requires :new_password, type: String, desc: "新密码"
        requires :new_password_confirmation, type: String, desc: "重复新密码"
      end
      put :password do
        authenticate!
        raise APIErrors::VeriftyFail, "原密码不正确!" unless current_user.valid_password?(params[:old_password])
        raise APIErrors::VeriftyFail, "两次输入的密码不一致!" if params[:new_password] != params[:new_password_confirmation]
        raise APIErrors::VeriftyFail, "新密码不能与原密码相同!" if params[:new_password] == params[:old_password]
        current_user.reset_password_with_validate!(params[:new_password], params[:new_password_confirmation])
      end

      add_desc "忘记密码接口"
      params do
        requires :mobile, type: String, desc: "手机号"
        requires :code, type: String, desc: "验证码"
        requires :new_password, type: String, desc: "新密码"
        requires :new_password_confirmation, type: String, desc: "重复新密码"
      end
      put :forget_password do
        @user = User.find_by_mobile(params[:mobile])

        raise APIErrors::VeriftyFail, "两次输入的密码不一致!" if params[:new_password] != params[:new_password_confirmation]
        raise APIErrors::VeriftyFail, Sms.error_info(params[:mobile]) unless Sms.verifty(params[:mobile], params[:code])
        @user.reset_password_with_validate!(params[:new_password], params[:new_password_confirmation])
      end

      add_desc "某用户关注组合或股票的集合", entity: ::Entities::Basket
      params do
        optional :all, using: ::Entities::Paginate.documentation
        optional :market, desc: "市场", type: String, values: %w[cn hk us]
        optional :type, desc: "类型(组合或股票)", type: String, values: %w[stock basket]
      end
      get ":user_id/following_all", requirements: { user_id: /[0-9]*/ } do
        @user = ::User.find(params[:user_id])

        @follows = Follow::Base.includes(:followable)
        @follows =
          case params[:type]
          when nil
            @follows.selected
          when "stock"
            @follows.for_stock
          when "basket"
            @follows.for_basket
          end
        @follows = @follows.by_user(@user.id).sort
        @follows = @follows.select{|f| f.followable_type == "Basket" ? f.followable.market == params[:market] : f.followable.class.name.demodulize.downcase == params[:market] } if params[:market]
        present paginate(@follows), with: ::Entities::OptionalFollow
      end

      add_desc "某用户关注的组合", entity: ::Entities::Basket
      params do
        optional :all, using: ::Entities::Paginate.documentation
        optional :market, desc: "市场", type: String, values: %w[cn hk us]
      end
      get ":user_id/following_baskets", requirements: { user_id: /[0-9]*/ } do
        @user = ::User.find(params[:user_id])
        @baskets = Follow::Basket.followed_baskets_by(@user.id).includes(:followable).map(&:followable)
        @baskets.select!{|b| b.market == params[:market] } if params[:market]
        present paginate(@baskets), with: ::Entities::Basket
      end

      add_desc "某用户创建的组合", entity: ::Entities::Basket
      params do
        optional :all, using: ::Entities::Paginate.documentation
      end
      get ":user_id/baskets", requirements: { user_id: /[0-9]*/ } do
        @user = ::User.find(params[:user_id])
        @baskets = @user.baskets.includes(:author).normal.finished.order("id desc")
        present paginate(@baskets), with: ::Entities::Basket
      end

      add_desc "某用户的自选股", entity: ::Entities::Stock
      params do
        optional :all, using: ::Entities::Paginate.documentation
        optional :market, desc: "市场", type: String, values: %w[cn hk us]
      end
      get ":user_id/following_stocks", requirements: { user_id: /[0-9]*/ } do
        @user = ::User.find(params[:user_id])
        # 如果不是当前用户并且没有查看权限
        if @user == current_user || @user.get_app_permission.all_following_stocks_real(current_user)
          @stocks = @user.stocks_of_followed
          @stocks.select!{|s| s.class.name.demodulize.downcase == params[:market] } if params[:market]
          present paginate(@stocks), with: ::Entities::Stock, type: :market
        else
          present []
        end
      end

      add_desc "我的自选行情"
      get :my_focused do
        authenticate!

        followed_stocks = current_user.stocks_of_followed
        positioned_stocks = Position.where(trading_account_id: TradingAccount.binded.by_user(current_user.id).pluck(:id), instance_id: "others").where("shares > 0").includes(:base_stock).map(&:base_stock).uniq

        stocks = followed_stocks | positioned_stocks

        followed_baskets = Follow::Basket.followed_baskets_by(current_user.id).includes(:followable).map(&:followable)
        positioned_baskets =
          TradingAccount.binded.by_user(current_user.id).map do |ta|
            Position.basket_positions_of_latest_updated(ta.id).map{|p| p.basket.newest_version }
          end.flatten.uniq

        baskets = followed_baskets | positioned_baskets

        result = {

          stocks: present(stocks, with: ::Entities::Stock, type: :market),
          baskets: present(baskets, with: ::Entities::Basket, type: :trade)

        }
        present result
      end

      add_desc "未登录用户的自选行情"
      params do
        optional :stock_ids, desc: "多个ids用,间隔", type: String
        optional :basket_ids, desc: "多个ids用,间隔", type: String
      end
      get :unlogin_focused do

        raise APIErrors::VeriftyFail, "stock_ids 格式不正确" unless params[:stock_ids].nil? || params[:stock_ids] =~ /^(\d+,?)+$/
        raise APIErrors::VeriftyFail, "basket_ids 格式不正确" unless params[:basket_ids].nil? ||  params[:basket_ids] =~ /^(\d+,?)+$/

        stock_ids = params[:stock_ids].try(:split, ",")
        basket_ids = params[:basket_ids].try(:split, ",")

        stocks = BaseStock.where(id: stock_ids)
        baskets = Basket.where(id: basket_ids)

        result = {

          stocks: present(stocks, with: ::Entities::Stock, type: :market),
          baskets: present(baskets, with: ::Entities::Basket, type: :trade)

        }
        present result
      end


    end

    add_desc "用户登录"
    params do
      requires :email_or_mobile, type: String, desc: "邮箱或者手机号码"
      requires :password, type: String, desc: "密码"
    end
    post :login do
      if @user = ::User.check_login?(params[:email_or_mobile], params[:password])

        @user.make_token(sn_code: sn_code)

        present @user, with: ::Entities::User, type: :token, current_user: @user

      else
        raise APIErrors::VeriftyFail, "登录失败，用户名或密码不正确"
      end
    end

    add_desc "登出"
    delete :logout do
      authenticate!
      current_user.api_tokens.first.update(expires_at: Time.now - 1.days)
    end

  end
end
