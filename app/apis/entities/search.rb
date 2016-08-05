module Entities
  module Search
    class Basket < ::Entities::Basket
      available_exposures :id, :title, :one_month_return, :followed, :market
    end

    class BasketWithoutTotalReturn < ::Entities::Basket
      available_exposures :id, :title, :author, :market, :full_tags, :one_day_return, :one_month_return, :one_year_return, :created_at
    end

    class BasketWithTotalReturn < ::Entities::Basket
      available_exposures :id, :title, :author, :market, :full_tags, :realtime_total_return, :created_at
    end

    class BasketForAdjustment < ::Entities::Basket
      available_exposures :id, :title, :author, :market, :full_tags, :realtime_total_return, :created_at, :last_ajustment_time, :ajustment_info_zh
    end
    
    class Stock < ::Entities::Stock
      available_exposures :id, :symbol, :com_name, :followed, :market_area_name, :listed_state, :is_index, :realtime_price, :change_percent, :change_from_previous_close, :up_price, :down_price
    end

    class User < ::Entities::User
      available_exposures :id, :username, :avatar, :city, :headline, :relationship
    end
  end
end
