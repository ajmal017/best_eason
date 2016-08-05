module Entities
  class Profile < ::Entities::Base
    expose :orientation, documentation: {type: String, desc: "投资方向"}
    expose :period, documentation: {type: String, desc: "一般持仓时间"}
    # 由于user对象存在concern方法，直接使用会直接调用
    # user.concern 所以手动设置一下
    expose :concern, documentation: {type: String, desc: "投资时最关注"} do |data, options|
      data.concern
    end
    expose :tags, documentation: {type: Array, desc: "能力圈"} do |data, options|
      data.tags.map(&:name)
    end
    expose :intro, documentation: {type: String, desc: "简介"}
  end

  class BaseUser < ::Entities::Base
    expose :id, documentation: {type: Integer, desc: "ID"}
    expose :username, documentation: {type: String, desc: "用户名"}
    expose :avatar, documentation: {type: String, desc: "头像"} do |data, options|
      data.avatar.url
    end
  end

  class User < ::Entities::BaseUser
    expose :headline, documentation: {type: String, desc: "头备注"}
    expose :gender, documentation: {type: Integer, values: [0, 1], desc: "性别, 0:F, 1:M"} do |data, options|
      if data.gender.nil?
        nil
      else
        data.gender ? "M" : "F"
      end
    end
    expose :province, documentation: {type: Integer, desc: "省份"}
    expose :city, documentation: {type: String, desc: "城市"}
    expose :intro, documentation: {type: String, desc: "简介"} do |data, options|
      data.profile.try(:intro)
    end
    expose :relationship, documentation: {type: Integer, desc: "关系：0: 本人, 1: 互相关注, 2: 你关注了他, 3: 他关注了你, 4: 互相无关注"} do |data, options|
      options[:current_user].try(:relation, data)
    end

    # TODO 有bug undefined method `to_d' for nil:NilClass
    expose :position_scale, documentation: {type: Float, desc: "该用户的仓位比例"}, format_with: :to_f do |data, options|
      data.get_app_permission.all_position_scale_real(options[:current_user]) || data.id == options[:current_user].try(:id) ? Position.user_percent_position(data.id) : nil
    end

    expose :mobile, documentation: {type: String, desc: "手机号"} do |data, options|
      options[:current_user].try(:id) == data.id ? data.mobile : nil
    end

    expose :email, documentation: {type: String, desc: "邮箱"} do |data, options|
      options[:current_user].try(:id) == data.id ? data.email : nil
    end

    expose :certification_exist, documentation: {type: Grape::API::Boolean, desc: "是否进行过实名验证"} do |data, options|
      data.certification_exists?
    end

    expose :p2p_account_exist, documentation: {type: Grape::API::Boolean, desc: "是否已开通理财宝"} do |data, options|
      data.p2p_account_exists?
    end

    expose :password_exist, documentation: {type: Grape::API::Boolean, desc: "密码是否存在 true为存在"} do |data, options|
      data.encrypted_password.present?
    end

    expose :following_baskets_count, documentation: {type: Integer, desc: "自选组合数"}
    expose :following_stocks_count, documentation: {type: Integer, desc: "自选股数"}
    expose :user_baskets_count, documentation: {type: Integer, desc: "创建组合数"} do |data, options|
      data.baskets_count
    end
    # ===============

    expose :followed_users_count, as: :followings_count, documentation: {type: Integer, desc: "关注数"}
    expose :follows_count, as: :followers_count, documentation: {type: Integer, desc: "粉丝数"}


    expose :notification_count, documentation: {type: Integer, desc: "通知数"} do |data, options|
      if options[:current_user].try(:id) == data.id
        ::Notification::Base.app_notification_types.where(user_id: data.id).count
      else
        0
      end
    end

    expose :shipan_data, documentation: {type: Hash, desc: "实盘大赛数据"}, if: ->(d,o){include_multiple_type? d, o} do |data, options|
      if data.pt?
        basket = ::Basket.shipan.find_by(user_id: data.id)

        contest = ::Contest.find(3)
        basket_rank = contest.basket_rank_of(basket.author_id)

        {
          basket_id: basket.id,
          basket_title: basket.title,
          victory: basket_rank.win_rate,
          now_rank: basket_rank.now_rank,
          total_profit: basket_rank.get_total_ret,
          rank_change: basket_rank.rank_change
        }
      else
        nil
      end
    end
    expose :friends_count, documentation: {type: Integer, desc: "好友数"}, if: ->(d,o){include_multiple_type? d, o} do |data, options|
      data.friends.count
    end
    expose :new_friends_count, documentation: {type: Integer, desc: "新好友数"}, if: ->(d,o){include_multiple_type? d, o} do |data, options|
      (data.follows.where("created_at >= ?", data.checked_at).map(&:user_id) & data.followings.map(&:followable_id)).count
    end
    expose :new_followers_count, documentation: {type: Integer, desc: "新粉丝数"}, if: ->(d,o){include_multiple_type? d, o} do |data, options|
      data.follows.where("created_at >= ?", data.checked_at).count
    end

    expose :common_friends_count, documentation: {type: Integer, desc: "共同好友数"}, if: ->(d,o){include_multiple_type? d, o} do |data, options|
      ((options[:current_user].try(:friends) || []) & data.friends).count
    end

    expose :orientation, documentation: {type: String, desc: "投资方向"}, if: ->(d,o){include_multiple_type? d, o} do |data, options|
      data.profile.try(:orientation)
    end
    expose :period, documentation: {type: String, desc: "一般持仓时间"}, if: ->(d,o){include_multiple_type? d, o} do |data, options|
      data.profile.try(:period)
    end
    expose :id_no, documentation: {type: String, desc: "身份证号"}, if: ->(d,o){include_multiple_type? d, o} do |data, options|
      data.user_certification.try(:hide_id_no)
    end
    expose :real_name, documentation: {type: String, desc: "真实姓名"}, if: ->(d,o){include_multiple_type? d, o} do |data, options|
      data.user_certification.try(:real_name)
    end
    expose :concern, documentation: {type: String, desc: "投资时最关注"}, if: ->(d,o){include_multiple_type? d, o} do |data, options|
      data.profile.try(:concern)
    end
    expose :tags, documentation: {type: Array, desc: "能力圈"}, if: ->(d,o){include_multiple_type? d, o} do |data, options|
      (data.profile.try(:tags)||[]).map(&:name)
    end
    expose :providers, documentation: {type: Hash, desc: "第三方帐号绑定情况"}, if: ->(d,o){include_multiple_type? d, o} do |data, options|
      data.provider_for_api
    end

    expose :articles_count, documentation: {type: Integer, desc: "专栏数"}, if: {type: :full} do |data, options|
      data.articles.count
    end
    expose :basket_total_return, documentation: {type: String, desc: "组合总体回报"}, if: {type: :full}
    expose :profile_fluctuation, as: :fluctuation, documentation: {type: String, desc: "波动"}, if: {type: :full}
    expose :focus, documentation: {type: Array, desc: "用户重点关注"}, if: {type: :full}

    expose :stock_position_scale, documentation: {type: Float, desc: "某支股票在该用户仓位中所占比例(该用户必须是当前登录用户的好友)"}, if: {type: :stock}, format_with: :to_f do |data, options|
      if options[:current_user].present? && options[:current_user].friend?(data) && options[:stock_id].present?
        data.get_app_permission.friend_position_scale ? Position.stock_percent_position(data.id, options[:stock_id]) : nil
      else
        nil
      end
    end

    expose :access_token, documentation: {type: String, desc: "用户token"}, if: {type: :token}
    expose :is_new, documentation: {type: Grape::API::Boolean, desc: "是否为新用户"}, if: {type: :token}

    private

    def access_token
      tokens = object.api_tokens
      tokens.first.access_token unless tokens.empty?
    end

    def focus
      object.focus_by_cache.to_a
    end

    def include_multiple_type?(data, options)
      %i(full profile token).include? options[:type]
    end

  end

  class UserForBasket < ::Entities::Base
    expose :id, documentation: {type: Integer, desc: "ID"}
    expose :username, documentation: {type: String, desc: "用户名"}
    expose :avatar, documentation: {type: String, desc: "头像"} do |data, options|
      data.avatar.url
    end
    expose :follows_count, as: :followers_count, documentation: {type: Integer, desc: "粉丝数"}
  end
end
