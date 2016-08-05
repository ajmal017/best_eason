module V1
  class Search < Grape::API

    resource :search, desc: "搜索相关" do

      before do
        @keyword = params[:keyword]
        @keyword_cn = Caishuo::Utils::Translate.cn(@keyword)
      end

      add_desc "根据用户昵称或者股票代码查询对应用户或股票的详情"
      params do
        requires :type, type: String, desc: "数据类型", values: %w[user stock stock_name]
        optional :keyword, type: String, desc: "关键字"
      end
      get :precise do
        case params[:type]
        when "user"
          raise ActiveRecord::RecordNotFound unless user = User.find_by(username: @keyword)
          present user, with: ::Entities::User, type: :profile
        when "stock"
          raise ActiveRecord::RecordNotFound unless stock = BaseStock.find_by(symbol: @keyword)
          present stock, with: ::Entities::Stock, type: :stock, stock_id: stock.id
        when "stock_name"
          raise ActiveRecord::RecordNotFound unless stock = BaseStock.where("c_name = ? or name = ?", @keyword, @keyword).first
          present stock, with: ::Entities::Stock, type: :stock, stock_id: stock.id
        end
      end

      add_desc "根据ids查询用户，股票，组合详情"
      params do
        optional :all, using: ::Entities::Paginate.documentation
        requires :type, type: String, desc: "数据类型", values: %w[user basket stock]
        requires :ids, type: String, desc: "用户ids, 多个id之间用,分割"
      end
      get do

        case params[:type]
        when "user"
          obj, entities_class, type = User, ::Entities::User, nil
        when "basket"
          obj, entities_class, type = Basket, ::Entities::Basket, :trade
        when "stock"
          obj, entities_class, type = BaseStock, ::Entities::Stock, :market
        end

        ids = params[:ids].split(",")
        datas = obj.where(id: ids)

        present paginate(datas), with: entities_class, type: type
      end

      add_desc "搜索用户", entity: ::Entities::User
      params do
        optional :all, using: ::Entities::Paginate.documentation
        optional :user_ids, type: String, desc: "用户ids, 多个id之间用,分割"
        optional :detail, type: Integer, desc: "是否要详细信息，1:详细"
        optional :keyword, type: String, desc: "关键字"
      end
      get :users do
        present [] and return if params[:user_ids].blank? && @keyword_cn.blank?

        users = User

        if params[:user_ids].present?
          user_ids = params[:user_ids].split(/,|，/)
          users = users.where(id: user_ids)
        end

        if @keyword_cn.present?
          users = users.where("username like ?", "#{@keyword_cn}%")
        end

        if params[:detail] == 1
          present paginate(users), with: ::Entities::User, type: :profile
        else
          present paginate(users), with: ::Entities::Search::User
        end
      end

      add_desc "搜索股票", entity: ::Entities::Stock
      params do
        optional :all, using: ::Entities::Paginate.documentation
        requires :keyword, type: String, desc: "关键字"
        optional :market, type: String, desc: "市场(多个用,分隔) (cn hk us)"
      end
      get :stocks do
        present [] and return if @keyword_cn.blank?
        stocks = BaseStock.fuzzy_query_for_api(@keyword_cn, limit: 1000, search_all: true, show_desc: false, market: params[:market])
        present paginate(stocks), with: ::Entities::Search::Stock
      end

      add_desc "搜索组合信息", entity: ::Entities::Basket
      params do
        optional :all, using: ::Entities::Paginate.documentation
        optional :all, using: ::Entities::BasketSearch.documentation
      end
      get :baskets do
        search_hash = {search_word: params[:keyword], tag: params[:tag], market: params[:market], order: params[:order], filter: params[:filter]}
        @baskets = Basket.includes(:tags).search_list(search_hash, params[:page])

        entity = if params[:keyword].present?
                    ::Entities::Search::Basket
                  else
                    case params[:order]
                    when "adjustment_at"
                      ::Entities::Search::BasketForAdjustment
                    when *["total_return", "start_date"]
                      ::Entities::Search::BasketWithTotalReturn
                    else
                      ::Entities::Search::BasketWithoutTotalReturn
                    end
                  end
        present paginate(@baskets), with: entity
      end

      add_desc "搜索用户,股票,组合, 每种类型只返回前4个"
      params do
        requires :keyword, type: String, desc: "关键字"
      end
      get :all do
        present({users: [], stocks: []}) and return if @keyword_cn.blank?
        users = User.search_by(@keyword_cn, 4)
        stocks = BaseStock.fuzzy_query_for_api(@keyword_cn, limit: 4, search_all: true, show_desc: false)
        baskets = Basket.search_list({search_word: params[:keyword], order: "1m_return"}).limit(4)

        # 删掉baskets的total_pages方法
        baskets.instance_eval{ undef total_pages }

        result = {
          users: present(users, with: ::Entities::Search::User),
          stocks: present(stocks, with: ::Entities::Search::Stock),
          baskets: present(baskets, with: ::Entities::Search::Basket)
        }
        present result
      end

    end

  end
end
