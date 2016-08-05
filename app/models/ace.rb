class Ace
  include RedisRecord

  has_attributes :user_id, :tag, :basket_id, :value_type, presence: :user_id

  VALUE_TYPE = %w[ day month total ]

  def user
    @user ||= User.find_by(id: user_id)
  end

  def value_type
    @value_type || VALUE_TYPE.first
  end

  def return_value
    case value_type
    when "day"
      user.basket_change_percent
    when "month"
      user.basket_total_return
    when "total"
      user.basket_real_total_return
    end
  rescue
    nil
  end

  def basket_id
    @basket_id.present? ? @basket_id.to_i : nil
  end

  def basket
    @basket ||= Basket.find_by(id: basket_id)
  end

  def basket_contest
    basket.try :contest
  end

  def basket_total_return
    basket.try :total_return
  end

  def self.result_for_app
    all_without_nil.map do |ace|
      r = {tag: ace.tag, basket_id: ace.basket_id, basket_contest: ace.basket_contest, value_type: ace.value_type}

      if ace.user.present?
        r[:user_id] = ace.user.id
        r[:username] = ace.user.username
        r[:avator] = ace.user.avatar.url
        r[:win_rate] = ace.user.max_win_rate
        r[:last_order_detail] = ace.user.last_order_detail_data
        r[:return_value] = ace.return_value
      end
      r
    end
  end

end
