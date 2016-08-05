class FeaturedBasket
  include RedisRecord

  has_attributes :basket_id, :reason, :value_type, presence: :basket_id

  VALUE_TYPE = %w[ day month total ]

  def basket
    @basket ||= Basket.find_by(id: basket_id)
  end

  def value_type
    @value_type || VALUE_TYPE.first
  end

  def return_value
    case value_type
    when "day"
      basket.change_percent.to_f
    when "month"
      basket.one_month_return.to_f
    when "total"
      basket.total_return.to_f
    end
  rescue
    nil
  end

  def self.result_for_app
    all_without_nil.map do |fb|
      r = {reason: fb.reason, value_type: fb.value_type}

      if fb.basket.present?
        r[:id] = fb.basket.id
        r[:title] = fb.basket.title
        r[:tags] = fb.basket.full_tags
        r[:market] = ::BaseStock::MARKET_AREA_NAMES[fb.basket.market.try(:to_sym)]
        r[:contest] = fb.basket.contest
        r[:return_value] = fb.return_value
      end
      r
    end
  end

end
