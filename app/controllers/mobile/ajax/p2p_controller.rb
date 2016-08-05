class Mobile::Ajax::P2pController < Mobile::ApplicationController
  layout false
  # 投资记录数据
  def inverst_records
    data = P2pService.product_buyers(nil, {last_id: params[:last_id], id: params[:id]})[0]
    format_data = data.map do |d|
      result = {mobile: d["user"]["mobile"], amount: d["amount"], created_at: (Time.parse(d["created_at"]).strftime("%Y.%m.%d") rescue nil) }
      result[:last_id] = d["last_id"] if d.has_key?("last_id")
      result
    end
    render :json => format_data.to_json
  end

  # 每日收益
  def day_profits
    @user = User.find(params[:uid].to_i)
    attrs = [@user, {page_size: params[:perpage]}]
    attrs[1].merge!(last_id: params[:last_id]) if params[:last_id].present?

    last_id = ''
    result = P2pService.user_daily_interest(*attrs)[0]
    data = result.map do |d|
      last_id = d['last_id'] if d == result.last
      { date: Date.parse(d.date).strftime("%Y.%m.%d"), gain: (d.float_interest.to_f + d.interest.to_f).round(2)  }
    end

    format_data = {
      lists: data,
      last_id: last_id
    }

    # TEST
    #format_data = {
      #lists: [
        #{date:'2015.10.01', gain:6789},
        #{date:'2015.10.01', gain:1234},
        #{date:'2015.10.01', gain:10294},
        #{date:'2015.10.01', gain:2695.65},
        #{date:'2015.10.01', gain:12564},
        #{date:'2015.10.01', gain:33694},
        #{date:'2015.10.01', gain:100}
      #],
      #last_id:'11'
    #}
    # TEST END

    render :json => format_data.to_json
  end
end

