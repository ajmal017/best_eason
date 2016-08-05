module V1
  class Chart < Grape::API
    formatter :json, JsonStringFormatter

    resource :stocks, desc: "股票相关" do

      add_desc "K线图"
      params do
        optional :start_date, type: String, desc: "开始时间,例：2015-03-1"
        optional :end_date, type: String, desc: "结束时间，例：2015-03-8"
        requires :precision, type: String, desc: "间隔,例：day/week/month", values: %w{day week month}
      end
      get "/:stock_id/charts/k" do

        # 设置Etag缓存
        compare_etag(60, Time.now.strftime("%Y%m%d%H%M"))

        if params[:precision] == "day"
          base_stock = BaseStock.find(params[:stock_id])
          datas = Kline.mobile_daily_quotes(base_stock, params.to_h.symbolize_keys)
        else
          kline_datas = RestClient.api.stock.native_kline(params[:stock_id], type: params[:precision], start_date: params[:start_date], end_date: params[:end_date])
          datas = kline_datas.reject {|item| item["volume"].blank? || item["volume"].zero?}
        end

        present datas
      end

    end
  end
end
