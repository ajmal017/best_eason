module V1
  class Relationships < Grape::API

    resource :relationships, desc: "用户关系相关" do

      before do
        @user = ::User.find(params[:user_id]) if params[:user_id].present?
      end

      add_desc "用户关注接口", entity: ::Entities::User
      post ":user_id/follow", requirements: { user_id: /[0-9]*/ } do
        authenticate!
        raise APIErrors::VeriftyFail, "关注对象不能为自己" if @user == current_user
        current_user.followed_users << @user if !@user.followed_by?(current_user)
        present @user, with: ::Entities::User, type: :profile
      end

      add_desc "用户取消关注接口", entity: ::Entities::User
      delete ":user_id/follow", requirements: { user_id: /[0-9]*/ } do
        authenticate!
        raise APIErrors::VeriftyFail, "关注对象不能为自己" if @user == current_user
        current_user.followed_users.destroy(@user) if @user.followed_by?(current_user)
        present @user, with: ::Entities::User, type: :profile
      end

      add_desc "关注用户(支持一次关注多个用户, 返回当前用户关注的user_ids)"
      params do
        requires :user_ids, desc: "多个ids用,间隔", type: String
      end
      post :follow do
        authenticate!

        raise APIErrors::VeriftyFail, "user_ids 不存在" unless params[:user_ids].present?
        raise APIErrors::VeriftyFail, "user_ids 格式不正确" unless params[:user_ids] =~ /^(\d+,?)+$/

        ids = params[:user_ids].split(",")

        @users = User.where(id: ids)

        @users.each do |user|
          current_user.followed_users << user unless user.followed_by?(current_user)
        end

        present current_user.followed_users.map(&:id)
      end

      add_desc "某用户好友列表接口", entity: ::Entities::User
      params do
        optional :all, using: ::Entities::Paginate.documentation
      end
      get ":user_id/friends", requirements: { user_id: /[0-9]*/ } do
        users = @user.friends.map(&:followable)
        present paginate(users), with: ::Entities::User
      end

      add_desc "某用户关注用户列表接口", entity: ::Entities::User
      params do
        optional :all, using: ::Entities::Paginate.documentation
      end
      get ":user_id/followings", requirements: { user_id: /[0-9]*/ } do
        users = @user.followed_users
        present paginate(users), with: ::Entities::User
      end

      add_desc "某用户粉丝列表接口", entity: ::Entities::User
      params do
        optional :all, using: ::Entities::Paginate.documentation
      end
      get ":user_id/followers", requirements: { user_id: /[0-9]*/ } do
        users = @user.followers
        present paginate(users), with: ::Entities::User
      end

      #add_desc "关注或者取消关注某只股票到我的组合里"
      #params do
        #requires :stock_id, type: Integer, desc: "股票id"
      #end
      #get "baskets/add" do
        #stock = ::BaseStock.find(params[:stock_id])
        #stock.follow_or_unfollow_by_user(1001)
      #end

      #add_desc "调整我关注的股票的排序"
      #params do
        #requires :stock_ids, type: String, desc: "交换位置的两只股票id(逗号间隔)"
      #end
      #get "baskets/sort_stock" do
        #stock_ids = params[:stock_ids].split(",")
        #follow_ids = stock_ids.map { |x, y| ::Follow.find(x.to_i, y.to_i).map(&:id) }
        #Follow.update_stock_follows_sort(current_user, follow_ids)
      #end

      #add_desc "我关注（取消关注）组合接口", entity: ::Entities::Basket
      #post "baskets/:basket_id", requirements: { basket_id: /[0-9]*/ } do
        #authenticate!
        #@basket = ::Basket.find(params[:basket_id])

        #@basket.follow_or_unfollow_by_user(current_user.id)
        #@basket.reload

        #present @basket, with: ::Entities::Basket
      #end

      #add_desc "我关注的组合列表接口", entity: ::Entities::Basket
      #params do
        #optional :all, using: ::Entities::Paginate.documentation
      #end
      #get "baskets/my" do
        #authenticate!
        #@baskets = Follow.followed_baskets_by_user(current_user.id).includes(:followable).map(&:followable)
        #present paginate(@baskets), with: ::Entities::Basket
      #end

      #add_desc "其他用户关注的组合列表接口", entity: ::Entities::Basket
      #params do
        #optional :all, using: ::Entities::Paginate.documentation
        #optional :user_id, type: Integer, desc: "用户id"
      #end
      #get "baskets/:user_id", requirements: { user_id: /[0-9]*/ } do
        #@user = ::User.find(params[:user_id])
        #@baskets = Follow.followed_baskets_by_user(@user.id).includes(:followable).map(&:followable)
        #present paginate(@baskets), with: ::Entities::Basket
      #end

    end

  end
end
