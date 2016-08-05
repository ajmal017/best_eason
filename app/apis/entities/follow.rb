module Entities
  class Follow < ::Entities::Base
    expose :id, documentation: {type: Integer, desc: "id"}
    expose :real_followable_type, as: :followable_type, documentation: {type: String, desc: "类型"}
    expose :real_followable_id, as: :followable_id, documentation: {type: Integer, desc: "id"}
    expose :created_at, documentation: {type: String, desc: "收藏时间"}
    expose :target_info, documentation: {type: Hash, desc: "收藏对象信息"} do |data, options|
      data.followable.show_info.merge({url: data.real_followable_url}) rescue {}
    end
  end

  class OptionalFollow < ::Entities::Base
    expose :price, documentation: {type: Float, desc: "关注时价格(股票)"}
    expose :change, documentation: {type: Float, desc: "涨跌幅"} do |data, options|
      data.followable_type == "Basket" ? data.return_from_follow.try(:to_f) : data.return_from_follow.try(:to_f)
    end
    expose :stock, using: "::Entities::Stock", documentation: {type: Hash, desc: "对应的股票"} do |data, options|
      data.followable unless data.followable_type == "Basket"
    end
    expose :basket, using: "::Entities::Basket", documentation: {type: Hash, desc: "对应的组合"} do |data, options|
      data.followable if data.followable_type == "Basket"
    end
  end
end
