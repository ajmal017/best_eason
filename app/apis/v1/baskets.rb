module V1
  class Baskets < Grape::API
    resource :baskets, desc: "组合相关" do

      before do
        @basket = ::Basket.finished.find(params[:basket_id]) if params[:basket_id].present?
      end

      add_desc "组合详情", entity: ::Entities::Basket
      get ":basket_id", requirements: { basket_id: /[0-9]*/ } do
        present @basket, with: ::Entities::Basket, type: :detail
      end

      add_desc "仓位详情 (现金颜色暂定为#CC3333)"
      get ":basket_id/stocks", requirements: { basket_id: /[0-9]*/ } do

        # 实盘大赛组合
        if @basket.shipan?

          grouped_stock_infos = @basket.pt_account.stocks_infos.group_by{|x| x[:sector_name]}
          sector_percents = grouped_stock_infos.map do |sector_name, infos|
            [sector_name, infos.map{|x| x[:single_position].round(2)}.reduce(:+).round(2)]
          end.to_h
          cash_percent = (100 - (sector_percents.values.reduce(:+) || 0)).round(2)

          grouped_stock_infos["现金"] = []
          sector_percents["现金"] = cash_percent

          result = grouped_stock_infos.map do |sector_name, infos|
            # 调整infos内容匹配stock接口
            {
              sector_name: sector_name,
              sector_scale: sector_percents[sector_name],
              sector_color: Sector.find_color_by_zh(sector_name),
              stocks: infos
            }
          end

        else
          sector_scale = @basket.position_scale
          grouped_basket_stocks = @basket.basket_stocks.includes(:stock).group_by{|bs| bs.stock.try(:sector_name) || "其他" }
          bals = @basket.basket_adjustments.first.basket_adjust_logs rescue nil
          result = sector_scale.map do |data|
            {
              sector_name: data[:name],
              sector_scale: data[:scale],
              sector_color: data[:color],
              stocks: present(grouped_basket_stocks[data[:name]] || [], with: ::Entities::BasketStock, bals: bals)
            }
          end
        end

        present result
      end

      add_desc "组合图表-回报曲线图"
      get ":basket_id/charts/return", requirements: { basket_id: /[0-9]*/ } do
        real_begin_date = @basket.created_one_year_ago? ? @basket.adjust_start_date : 1.years.ago.to_date
        begin_date = @basket.created_one_year_ago? ? @basket.start_date : 1.years.ago.to_date
        end_date = Time.now.hour<20 ? (Date.today-1) : Date.today

        market_name = @basket.market_index_name
        market_data = @basket.market_indices_with_realtime_point(begin_date, end_date)
        basket_real_indices = @basket.real_indices_with_realtime_point(real_begin_date, end_date)
        basket_simulated_indices = @basket.created_one_year_ago? ? [] : @basket.simulated_indices_for_chart_cached(begin_date, end_date)

        present({market_name: market_name, market_data: market_data, basket: basket_real_indices, simulated: basket_simulated_indices, created_timestamp: (@basket.start_date.to_time+8.hours).to_i * 1000})
      end

      add_desc "发现 (注: hot_tags 返回4个，baskets 返回10个，不支持分页)"
      #params do
        #requires :basket_order, type: String, desc: "组合排序类型", values: ["1d_return", "total_return", "modified_at"], default: "1d_return"
      #end
      get :discovery do

        result = {}
        hot_tags_count = 4
        baskets_count = 10

        banners = MobileRecommend.banner_url_and_images.map do |id, infos|
          {
            type: infos[:type],
            url: infos[:image_url],
            link: infos[:url]
          }
        end
        result[:banners] = present banners
        result[:notification_count] = current_user.present? ? ::Notification::Base.app_notification_types.where(user_id: current_user.id).count : 0

        # 热门标签
        hot_tags = ::Tag::Common.normal.hot.order(:sort).limit(hot_tags_count)
        result[:hot_tags] = present(hot_tags, with: ::Entities::Tag)

        ## 今日热门组合
        #baskets = Basket.search_list({order: params[:basket_order], per_page: baskets_count}, 1)
        #baskets.class_eval { undef_method :total_pages }
        #result[:baskets] = present(baskets, with: ::Entities::Basket)

        result[:ad] = ::MobileRecommend.ad_infos(headers["X-Client-Version"])
        present result
      end

      add_desc "发现2"
      get :discovery2 do
        # redis 缓存 5分钟
        data = $cache.fetch("app:discovery2", :expires_in => 300) do
          result = {}
          banners = MobileRecommend.banner_url_and_images.map do |id, infos|
            {
              type: infos[:type],
              url: infos[:image_url],
              link: infos[:url]
            }
          end
          # 推荐图
          result[:banners] = present banners

          # 高手
          result[:aces] = present(Ace.result_for_app)

          # 精选组合
          result[:featured_baskets] = present(FeaturedBasket.result_for_app)

          # 每日新闻
          topics = Topic.visible.sort_by_modified_at.limit(20).map do |t|
            {
              id: t.id,
              tag: [t.title],
              title: t.sub_title,
              modified_at: t.modified_at
            }
          end

          result[:news] = present(topics)
          result
        end
        present data
      end

      add_desc "发现2-含有实时数据"
      get :discovery2_realtime do

        result = {}

        # 面板
        result[:panels] = present(Panel.result_for_app)

        # 热门股票
        result[:hots] = present(HotStock.result_for_app)

          # 提醒数量
        result[:notification_count] = current_user.present? ? ::Notification::Base.app_notification_types.where(user_id: current_user.id).count : 0

        present result
      end

      add_desc "调仓记录, action {1 => '新增', 2 => '删除', 3 => '加仓', 4 => '减仓'} ", entity: ::Entities::BasketAdjustment
      params do
        optional :all, using: ::Entities::Paginate.documentation
      end
      get ":basket_id/adjust_logs", requirements: { basket_id: /[0-9]*/ } do
        bals = @basket.basket_adjustments
        present paginate(bals), with: ::Entities::BasketAdjustment
      end

      add_desc "组合热门标签", entity: ::Entities::Tag
      params do
        optional :all, using: ::Entities::Paginate.documentation
      end
      get :tags do
        @tags = ::Tag::Common.normal.hot.order(:sort)
        present paginate(@tags), with: ::Entities::Tag
      end

      add_desc "关注组合", entity: ::Entities::Basket
      post ":basket_id/follow", requirements: { basket_id: /[0-9]*/ } do
        authenticate!

        @basket.follow_or_unfollow_by_user(current_user.id) if !@basket.followed_by_user?(current_user.id)

        present @basket, with: ::Entities::Basket
      end

      add_desc "取消关注组合", entity: ::Entities::Basket
      delete ":basket_id/follow", requirements: { basket_id: /[0-9]*/ } do
        authenticate!

        @basket.follow_or_unfollow_by_user(current_user.id) if @basket.followed_by_user?(current_user.id)

        present @basket, with: ::Entities::Basket
      end

      add_desc "关注组合(支持一次关注多个组合, 返回当前用户关注的basket_ids)"
      params do
        requires :basket_ids, desc: "多个ids用,间隔", type: String
      end
      post :follow do
        authenticate!

        raise APIErrors::VeriftyFail, "basket_ids 不存在" unless params[:basket_ids].present?
        raise APIErrors::VeriftyFail, "basket_ids 格式不正确" unless params[:basket_ids] =~ /^(\d+,?)+$/

        ids = params[:basket_ids].split(",")

        @baskets = Basket.where(id: ids)

        @baskets.each do |basket|
          basket.follow_or_unfollow_by_user(current_user.id) unless basket.followed_by_user?(current_user.id)
        end

        present Follow::Basket.followed_baskets_by(current_user.id).map(&:followable_id)
      end

      add_desc "取消关注组合(支持一次取消关注多个组合, 返回当前用户关注的basket_ids)", entity: ::Entities::Basket
      params do
        requires :basket_ids, desc: "多个ids用,间隔", type: String
      end
      delete :follow do
        authenticate!

        raise APIErrors::VeriftyFail, "basket_ids 不存在" unless params[:basket_ids].present?
        raise APIErrors::VeriftyFail, "basket_ids 格式不正确" unless params[:basket_ids] =~ /^(\d+,?)+$/

        ids = params[:basket_ids].split(",")

        @baskets = Basket.where(id: ids)

        @baskets.each do |basket|
          basket.follow_or_unfollow_by_user(current_user.id) if basket.followed_by_user?(current_user.id)
        end

        present Follow::Basket.followed_baskets_by(current_user.id).map(&:followable_id)
      end

    end


  end
end
