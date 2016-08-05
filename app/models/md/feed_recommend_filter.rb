module MD

  class FeedRecommendFilter

    TYPES = {
      filter_zjbklx_1: {
        name: "今日行业板块主力资金流入",
        data: MD::Data::PlateFundFlow::Industry.sort,
        limit: 100,
        time_rule: [5],
        category: :filter,
        item_limit: 4
      },
      filter_zjbklx_2: {
        name: "今日概念板块主力资金流入",
        data: MD::Data::PlateFundFlow::Concept.sort,
        limit: 100,
        time_rule: [5],
        category: :filter,
        item_limit: 4
      },
      filter_industry_1: {
        name: "热门行业",
        data: MD::Data::Plate::HotIndustry.sort,
        limit: 100,
        time_rule: [2, 3, 5],
        category: :filter
      },
      filter_concept_1: {
        name: "热门概念",
        data: MD::Data::Plate::HotConcept.sort,
        limit: 100,
        time_rule: [2, 3, 5],
        category: :filter
      },
      filter_ggzjlx_1: {
        name: "今日个股主力净流入",
        data: MD::Data::StockTradingFlow.latest.order(main_value: :desc),
        limit: 100,
        time_rule: [5],
        category: :filter
      },
      filter_ggzjlx_2: {
        name: "今日个股主力净流出",
        data: MD::Data::StockTradingFlow.latest.order(main_value: :asc),
        limit: 100,
        time_rule: [5],
        category: :filter
      },
      filter_ggcg_1: {
        name: "高管一个月净增持排行榜",
        data: MD::Data::LeaderStockAlter.order(value: :desc),
        limit: 100,
        time_rule: [3],
        category: :filter
      },
      filter_ggcg_2: {
        name: "高管一个月净减持排行榜",
        data: MD::Data::LeaderStockAlter.order(value: :asc),
        limit: 100,
        time_rule: [3],
        category: :filter
      },
      filter_lhb_1: {
        name: "当日涨幅偏离值达7%的证券",
        data: MD::Data::Longhu.latest.where(reason_type: 1),
        limit: 100,
        time_rule: [3],
        category: :filter
      },
      filter_lhb_2: {
        name: "当日跌幅偏离值达7%的证券",
        data: MD::Data::Longhu.latest.where(reason_type: 2),
        limit: 100,
        time_rule: [3],
        category: :filter
      },
      filter_lhb_3: {
        name: "当日换手率达到20%的证券",
        data: MD::Data::Longhu.latest.where(reason_type: 3),
        limit: 100,
        time_rule: [3],
        category: :filter
      },
      filter_lhb_4: {
        name: "当日价格振幅达到15%的证券",
        data: MD::Data::Longhu.latest.where(reason_type: 4),
        limit: 100,
        time_rule: [3],
        category: :filter
      },
      filter_lhb_5: {
        name: "连续三日涨幅累计超20%",
        data: MD::Data::Longhu.latest.where(reason_type: 5),
        limit: 100,
        time_rule: [3],
        category: :filter
      },
      filter_lhb_6: {
        name: "连续三日跌幅累计超20%",
        data: MD::Data::Longhu.latest.where(reason_type: 6),
        limit: 100,
        time_rule: [3],
        category: :filter
      },
      filter_score_1: {
        name: "财说SCORE高评分 买入策略",
        data: StockScreener.order(score: :desc).qualified,
        limit: 20,
        time_rule: [3],
        category: :filter
      },
      filter_score_2: {
        name: "财说SCORE低评分 卖出策略",
        data: StockScreener.order(score: :asc).qualified,
        limit: 20,
        time_rule: [3],
        category: :filter
      },
      filter_wr_1: {
        name: "WR超卖 买入策略",
        data: MD::Data::Wr.latest.buy,
        limit: 20,
        time_rule: [3],
        category: :filter
      },
      filter_wr_2: {
        name: "WR超买 卖出策略",
        data: MD::Data::Wr.latest.sell,
        limit: 20,
        time_rule: [3],
        category: :filter
      },
      filter_macd_1: {
        name: "MACD金叉 买入策略",
        data: MD::Data::Macd.latest.buy,
        limit: 20,
        time_rule: [3],
        category: :filter
      },
      filter_macd_2: {
        name: "MACD死叉 卖出策略",
        data: MD::Data::Macd.latest.sell,
        limit: 20,
        time_rule: [3],
        category: :filter
      }
    }


    FILTER_TYPES = TYPES.keys

    # limit小于0取全部数据
    def self.find(type_name, limit=nil)
      filter = TYPES[type_name.to_sym]
      filter[:data].limit(limit||filter[:limit]).to_a
    end


    def self.publish_to_feed_hub(filter_type)
      MD::FeedHub.add_single_filter(filter_type) rescue nil
    end


    def self.publish_to_private_feed(user_id, type_name, feed_type)
      filter = TYPES[type_name.to_sym]
      stocks = filter[:data].limit(filter[:item_limit] || 3).map(&:pretty_json)
      return if stocks.blank?
      MD::Feed::Filter.add(user_id, feed_type, type_name, filter[:name], stocks)
    end
    

    def self.clean_from_hub(feed_type=nil)
      feed_hubs = MD::FeedHub.where(recommend_category: "filter")
      feed_hubs = feed_hubs.where(feed_type: feed_type.to_s) if feed_type
      feed_hubs.update_all(reader_ids: [], clicks_count: 0, clicker_ids: [], created_at: Time.now)
    end

    def self.generate_all(feed_type=nil)
      types = MD::FeedRecommendFilter::TYPES.keys.find_all{|k| k.to_s =~ /#{feed_type}/}
      types.each{|k| publish_to_feed_hub(k)}
    end

  end

end
