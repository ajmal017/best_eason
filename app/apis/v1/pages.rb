module V1
  class Pages < Grape::API
    resource :pages, desc: "Pages页信息相关" do

      before do
        @record_origin = ::Follow::Base::FAVORITE_TYPES_KLASS[params[:type]].find(params[:id])
        @record = @record_origin.respond_to?(:staticable) ? @record_origin.staticable : @record_origin
      end

      add_desc "信息汇总"
      params do
        requires :type, desc: "类型", values: ::Follow::Base::FAVORITE_TYPES
      end
      get ":type/:id/infos" do
        case params[:type]
        when "topic"
          stocks_base = @record_origin.topic_stocks.fixed.includes(base_stock: [:stock_screener]) rescue []
          stocks = stocks_base.limit(5).map(&:base_stock) rescue []
        when "news"
          stocks_base = @record_origin.topic_stocks rescue []
          stocks = stocks_base.limit(5) rescue []
        else
          stocks = []
        end
        baskets_base = @record_origin.selected_topic_baskets.includes(:author, :tags) rescue []
        baskets = baskets_base.limit(5) rescue []

        result = {}
        result[:stocks] = present(stocks, with: ::Entities::IndexStock)
        result[:baskets] = present(baskets, with: ::Entities::Basket)

        result[:infos] = {
          comments_count: (@record.comments_count rescue 0),
          stocks_count: (stocks_base.count rescue 0),
          baskets_count: baskets_base.count,
          is_favorite: (@record.followed_by_user?(current_user.try(:id)) rescue false)
        }
        present result
      end

      # TODO 为了支持已上线的app,暂时不进行分页，下一板上线前加入
      add_desc "相关股", entity: ::Entities::IndexStock
      params do
        requires :type, desc: "类型", values: ::Follow::Base::FAVORITE_TYPES
      end
      get ":type/:id/stocks" do
        
        case params[:type]
        when "topic"
          stocks_base = @record_origin.topic_stocks.fixed.includes(base_stock: [:stock_screener]) rescue []
          stocks = stocks_base.map(&:base_stock) rescue []
        when "news"
          stocks = @record_origin.topic_stocks rescue []
        else
          stocks = []
        end
        present stocks, with: ::Entities::IndexStock
      end

      # TODO 为了支持已上线的app,暂时不进行分页，下一板上线前加入
      add_desc "相关组合", entity: ::Entities::Basket
      params do
        requires :type, desc: "类型", values: ::Follow::Base::FAVORITE_TYPES
      end
      get ":type/:id/baskets" do
        baskets = @record_origin.selected_topic_baskets rescue []
        present(baskets, with: ::Entities::Basket)
      end
    end
  end
end
