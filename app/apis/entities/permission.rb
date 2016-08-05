module Entities
  class AppPermission < ::Entities::Base
    expose :all_following_stocks, documentation: {type: Grape::API::Boolean, desc: "所有人-自选股"}
    expose :all_position_scale, documentation: {type: Grape::API::Boolean, desc: "所有人-仓位比重"}
    expose :friend_position_scale, documentation: {type: Grape::API::Boolean, desc: "好友-仓位比重"}
  end
end
