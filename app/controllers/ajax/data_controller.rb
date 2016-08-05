class Ajax::DataController < Ajax::ApplicationController
  skip_before_action :require_xhr?

  def contest_cash
    cash, timestamp = $redis.mget('contest_cash', 'contest_timestamp')
    now = Time.now.strftime('%H%M')
    datas = {trading: Stock::Cn.trading?, timestamp: Time.now.to_i*1000}
    # if !Stock::Cn.market_open? || (now < '1300' && now > '1130') || now > '1500' || now < '0900'
      render json: datas.merge(cash: cash.to_f)
    # else
    #   render json: datas.merge(cash: cash.to_f + (Time.now.to_i - timestamp.to_i)*rand(16))
    # end
  end

  def events
    @active_dock = ActiveDock.find_by(short_id: params[:short_id])
    render json: @active_dock.dock_date
  end
end
