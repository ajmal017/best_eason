class P2pService

  class << self

    # User
    # =======================================================

    # P2P开户
    # 1. 检验用户是否已经开过户
    # 2. 检验用户是否存在绑定手机号
    # 3. 检验用户是否已实名认证
    # 4. 调用接口进行开户
    # 5. 如果返回开户成功, 创建对应trading_account
    # 6. 创建成功后，返回trading_account账户
    def user_open(user=nil, opts={})
      raise "存在绑定账户" if user.p2p_account_exists?
      raise "还未绑定手机号" unless user.mobile_exists?
      raise "还未进行实名认证" unless user.certification_exists?

      opts = {
        caishuo_id: user.id,
        mobile: user.mobile,
        name: user.user_certification.real_name,
        identity: user.user_certification.id_no
      }
      response, headers = client_api('accounts', 'create', nil, opts)

      ta = TradingAccountP2p.new.tap do |ta|
        broker = Broker.p2p_broker
        ta.user = user
        ta.broker = broker
        ta.broker_no = response.token
        ta.cash_id = "#{broker.master_account}_#{response.token}"
      end
      ta.save!
      [ta, headers]
    end

    # 验证实名认证
    def user_certification(user=nil, opts={})
      client_api('accounts', 'certification', nil, opts)
    end

    # 用户列表
    def user_list(user=nil, opts={})
      client_api('accounts', 'list', nil, opts)
    end

    # 用户理财宝已购买产品(可选择用户)
    def user_products(user=nil, opts={})
      client_api('accounts', 'products', nil, opts)
    end

    # 用户理财宝已购买产品(当前用户)
    def current_user_products(user=nil, opts={})
      client_api('orders', 'products', user.try(:p2p_token), opts)
    end

    # 用户理财宝交易记录
    def user_orders(user=nil, opts={})
      client_api('orders', 'orders', user.try(:p2p_token), opts)
    end

    # 用户理财宝账户详情
    def user_profile(user=nil, opts={})
      client_api('orders', 'profile', user.try(:p2p_token), opts)
    end

    # 用户每日收益
    def user_daily_interest(user=nil, opts={})
      client_api('orders', 'daily_interest', user.try(:p2p_token), opts)
    end

    # =======================================================
    # User END

    # Product
    # =======================================================

    # 产品列表
    def products(user=nil, opts={})
      client_api('products', 'list', nil, opts)
    end

    # 产品详情
    def product(user=nil, opts={})
      product, headers = client_api('products', 'get', nil, opts)
      p2p_strategy = P2pStrategy.find(product.package["metadata"]["id"].to_i) rescue nil
      [product.merge({ trend_image: p2p_strategy.try(:index_image) }), headers]
    end

    # 用户购买的产品详情
    def product_detail(user=nil,  opts={})
      client_api('products', 'detail', user.try(:p2p_token), opts)
    end

    # 购买者列表
    def product_buyers(user=nil, opts={})
      client_api('products', 'buyers', nil, opts)
    end

    # 下单
    # amount:, bank_id: nil,bank_card_number: nil, bank_card_mobile: nil, bank_card_id: nil, user_terminal_info: nil, user_terminal_ip: nil
    def product_buy(user=nil, opts={})
      client_api('products', 'buy', user.try(:p2p_token), opts)
    end

    # =======================================================
    # Product END

    # Product_Package
    # =======================================================

    # 产品包列表
    def packages(user=nil, opts={})
      packages_list, headers = client_api('packages', 'list', nil, opts)
      packages_list = packages_list.map do |package|
        package_ids = package.products.map{|p| p["package"]["metadata"]["id"].to_i} rescue []
        p2p_strategy = P2pStrategy.where(id: package_ids, change_type: "up").first
        package.merge({ trend_image: p2p_strategy.try(:index_image) })
      end
      [packages_list, headers]
    end

    # 产品包详情
    def package(user=nil, opts={})
      client_api('packages', 'get', nil, opts)
    end

    # =======================================================
    # Product_Package END

    # Pay
    # =======================================================

    # 银行列表
    def banks(user=nil, opts={})
      client_api('payments', 'banks', nil)
    end

    # 用户银行卡列表
    def bankcards(user=nil, opts={})
      client_api('payments', 'bankcards', user.try(:p2p_token), user: user.id)
    end

    # 短信验证码验证
    def confirm_validation_code(user=nil, opts={})
      client_api('payments', 'confirm_validation_code', user.try(:p2p_token), opts)
    end

    # 短信验证码验证
    def resend_sms(user=nil, opts={})
      client_api('payments', 'resend_sms', user.try(:p2p_token), opts)
    end

    # 取消订单
    def cancel_order(user=nil, opts={})
      client_api('payments', 'cancel', user.try(:p2p_token), opts)
    end

    # =======================================================
    # Pay END

    def client_doc(namespace, method)
      P2pClient.doc(namespace, method)
    end

    def client_api(namespace, method, token=nil, opts={})
      rp = P2pClient.api(namespace, method, token, opts)
      raise ::APIErrors::P2pResponseError.new(nil, rp) unless rp.success
      [rp.data, rp.headers]
    end

  end
end
