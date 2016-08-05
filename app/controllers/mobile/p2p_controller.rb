class Mobile::P2pController < Mobile::ApplicationController
  before_action :authenticate_user!, only: [:day_profits]

  # 每日收益
  def day_profits
    @page_title = "收益"
    @chart_data = P2pService.user_daily_interest(@current_user, { page_size: 7 })[0].reverse.map do |n|
      {date: Date.parse(n.date).strftime("%m-%d"), gain: n.float_interest.to_f, bonus: n.interest.to_f}
    end.to_json

    # TEST
    #@current_user = User.first
    #@chart_data = [
      #{date:'10-18',gain:100, bonus:80},
      #{date:'10-19',gain:200, bonus:0},
      #{date:'10-20',gain:200, bonus:0},
      #{date:'10-21',gain:150, bonus:50},
      #{date:'10-15',gain:1000, bonus:100},
      #{date:'10-16',gain:2000, bonus:1000},
      #{date:'10-17',gain:100, bonus:20},
    #].to_json
    # TEST END
    render 'day_profits', layout: 'mobile/common'
  end

  # 产品详情（分享用）
  def product
    @page_title = "财说炒股宝"
    @product = P2pService.product(nil, {id: params[:id]})[0]
    @inverst_records_url = "/mobile/ajax/p2p/inverst_records"
    @data = {
      type: (@product.package['type'] rescue "up"), # 买涨:'up', 买跌: 'down'
      index: @product.name,
      base: (@product.expected_earning_rate.to_f * 100), # 固收
      extra_min: (@product.floating_earning_rate_min.to_f * 100), # 涨赢最小值
      extra_max: (@product.floating_earning_rate_max.to_f * 100), # 涨赢最大值
      note: @product.how_it_works,
      property: {
        holding: @product.period, # 投资期限（单位:月）
        holding_unit: @product.period_type,
        min: @product.min_amount, # 起投金额（单位:元）
        start: (Date.parse(@product.publish_time).strftime("%Y.%m.%d") rescue "") # 起息日
      },
      description: [
        ["还款方式", @product.pay_method]
      ],
      # description: [
      #  ["赎回方式", "T+2"],
      #  ["还款方式", "随投随取，安享收益，按月返息"],
      #  ["赎回机制", "投资后可随时申请赎回"]
      # ],
      detail: {
        project: @product.description,
        safeguard: @product.warrant_description
      }
    }.to_json
    render 'product', layout: 'mobile'
  end

  # 玩法规则
  def return_rule
  end

  # 出借咨询与服务协议 product_id
  def lending_protocol
    @title = "出借咨询与服务协议"
    render_nothing
  end

  # 出借通知单 product_id
  def lending_notice
    @title = "出借通知单"
    render_nothing
  end

  # 数字证书服务协议 product_id
  def dc_protocol
    @title = "数字证书服务协议"
    render_nothing
  end

  # 合同协议 product_id user_id
  def contract_protocol
    @title = "合同协议"
    render_nothing
  end

  # 财说协议
  def caishuo_protocol
    @title = "财说协议"
    render_nothing
  end

  # 常见问题及解答
  def common_issues
  end

  def render_nothing
    render text: "#{@title} - Nothing to do"
  end

end
