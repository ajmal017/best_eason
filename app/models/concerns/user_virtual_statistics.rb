module UserVirtualStatistics
  extend ActiveSupport::Concern

  included do
    attr_accessor :following_baskets_count, :following_stocks_count, :user_baskets_count
  end

  module ClassMethods
    def expand_users(users)

      user_ids = users.pluck(:id)

      follow_result = Follow::Base.select("user_id, count(1) as follow_count, followable_type").where(user_id: user_ids, followable_type: %w[ BaseStock Basket ]).group([:user_id, :followable_type]).group_by(&:user_id)
      #basket_result = Basket.select("author_id, count(1) as basket_count").normal.not_archived.where(author_id: user_ids).group(:author_id)

      users = users.map do |user|

        # 关注相关数量统计
        follow_count_arr = follow_result[user.id]
        if follow_count_arr.nil?
          user.following_baskets_count = 0
          user.following_stocks_count = 0
        else
          user.following_baskets_count = follow_count_arr.find{|ca| ca.followable_type == "Basket" }.try(:follow_count).to_i
          user.following_stocks_count = follow_count_arr.find{|ca| ca.followable_type == "BaseStock" }.try(:follow_count).to_i
        end

        # 创建相关数量统计
        #user.user_baskets_count = basket_result.find{|br| br.author_id == user.id }.try(:basket_count).to_i

        user
      end

    end
  end
end
