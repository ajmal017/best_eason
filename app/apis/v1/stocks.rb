module V1
  class Stocks < Grape::API
    resource :stocks, desc: "股票相关" do

      add_desc "分时图"
      params do
        requires :days, type: String, desc: "间隔,例：1, 5", values: %w{1 5}
      end
      get "/:stock_id/charts/minutes" do
        data = RestClient.api.stock.native_bar(params[:stock_id], params[:days])
        present data.blank? ? [] : data
      end

      add_desc "大盘整体行情"
      get :indexes do
        data = RestClient.api.stock.indexes
        index_data = data["data"]
        index_data.delete_if{ |x| x["symbol"] == "csi300" }

        index_data.map!{ |x| x.inject({}){|h,k| h[k[0]] = k[0] == "symbol" ? k[1] : (k[1].gsub(",", "").to_f rescue 0); h } }
        a = ["sh", "sz", "gem", "hs", "bp", "nasdq"]
        last_data = index_data.sort_by{ |x| a.index(x["symbol"]) }
        last_data.map!{ |x| x.merge({id: BaseStock.send(x["symbol"]).id}) }
        present last_data
      end

      add_desc "股票实时数据(可查多支股票)", entity: ::Entities::RealTimeStock
      params do
        requires :stock_ids, desc: "多个ids用,间隔", type: String
      end
      get "/real_time" do
        raise APIErrors::VeriftyFail, "stock_ids 不存在" unless params[:stock_ids].present?
        raise APIErrors::VeriftyFail, "stock_ids 格式不正确" unless params[:stock_ids] =~ /^(\d+,?)+$/

        ids = params[:stock_ids].split(",")
        @stocks = BaseStock.where(id: ids)

        present @stocks, with: ::Entities::RealTimeStock, type: :stock
      end

      add_desc "逐笔交易数据"
      get "/:stock_id/rt_logs" do
        stock = BaseStock.find(params[:stock_id])
        present stock.rt_logs
      end

      add_desc "根据股票代号，查看股票详情", entity: ::Entities::Stock
      params do
        requires :stock_id, desc: "股票id", type: Integer
      end
      get "/:stock_id" do
        stock = BaseStock.find(params[:stock_id])
        present stock, with: ::Entities::Stock, type: :stock, stock_id: params[:stock_id]
      end

      add_desc "股票相关信息(评分，相关股，新闻，简介，公告)", entity: ::Entities::StockDetail
      get "/:stock_id/detail" do
        stock = BaseStock.find(params[:stock_id])
        if stock.is_index?
          present stock, with: ::Entities::StockDetail, type: :index
        else
          present stock, with: ::Entities::StockDetail
        end
      end

      add_desc "股票实时数据", entity: ::Entities::RealTimeStock
      get "/:stock_id/real_time" do
        stock = BaseStock.find(params[:stock_id])
        present stock, with: ::Entities::RealTimeStock, type: :stock
      end

      add_desc "新增自选股", entity: ::Entities::Stock
      post ":stock_id/follow", requirements: { stock_id: /[0-9]*/ } do
        authenticate!

        @stock = BaseStock.find(params[:stock_id])

        @stock.follow_or_unfollow_by_user(current_user.id) if !@stock.followed_by_user?(current_user.id)

        present @stock, with: ::Entities::Stock
      end

      add_desc "删除自选股", entity: ::Entities::Stock
      delete ":stock_id/follow", requirements: { stock_id: /[0-9]*/ } do
        authenticate!

        @stock = BaseStock.find(params[:stock_id])

        @stock.follow_or_unfollow_by_user(current_user.id) if @stock.followed_by_user?(current_user.id)

        present @stock, with: ::Entities::Stock
      end

      add_desc "新增自选股(支持一次新增多个自选股, 返回当前用户的自选股ids)"
      params do
        requires :stock_ids, desc: "多个ids用,间隔", type: String
      end
      post :follow do

        authenticate!

        raise APIErrors::VeriftyFail, "stock_ids 不存在" unless params[:stock_ids].present?
        raise APIErrors::VeriftyFail, "stock_ids 格式不正确" unless params[:stock_ids] =~ /^(\d+,?)+$/

        ids = params[:stock_ids].split(",")

        @stocks = BaseStock.where(id: ids)

        @stocks.each do |stock|
          stock.follow_or_unfollow_by_user(current_user.id) unless stock.followed_by_user?(current_user.id)
        end

        present Follow::Stock.followed_stocks_by(current_user.id).map(&:followable_id)
      end

      add_desc "删除自选股(支持一次删除多个自选股, 返回当前用户的自选股ids)"
      params do
        requires :stock_ids, desc: "多个ids用,间隔", type: String
      end
      delete :follow do

        authenticate!

        raise APIErrors::VeriftyFail, "stock_ids 不存在" unless params[:stock_ids].present?
        raise APIErrors::VeriftyFail, "stock_ids 格式不正确" unless params[:stock_ids] =~ /^(\d+,?)+$/

        ids = params[:stock_ids].split(",")

        @stocks = BaseStock.where(id: ids)

        @stocks.each do |stock|
          stock.follow_or_unfollow_by_user(current_user.id) if stock.followed_by_user?(current_user.id)
        end

        present Follow::Stock.followed_stocks_by(current_user.id).map(&:followable_id)
      end

    end
  end
end
