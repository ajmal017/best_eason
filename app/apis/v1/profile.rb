module V1
  class Profile < Grape::API

    resource :profile, desc: "用户详情相关" do

      add_desc "用户详情", entity: ::Entities::User
      get ":user_id", requirements: { user_id: /[0-9]*/ } do
        user = User.find(params[:user_id])
        present user, with: ::Entities::User, type: :profile
      end

      add_desc "修改个人信息", entity: ::Entities::User
      params do
        optional :user, type: Hash, default: {} do
          optional :all, using: ::Entities::User.documentation.slice(:username, :headline, :intro, :province, :city, :gender)
        end
      end
      put do
        authenticate!

        _attrs = params[:user].dup.to_hash
        _attrs.delete("intro")

        current_user.update_attributes!(_attrs.to_hash)
        (current_user.profile || current_user.create_profile).update(intro: params[:user][:intro]) if params[:user].has_key?(:intro)

        present current_user, with: ::Entities::User
      end

      add_desc "上传头像", entity: ::Entities::User
      params do
        optional :user, type: Hash, default: {} do
          optional :avatar, type: Rack::Multipart::UploadedFile
        end
      end
      put :avatar do
        authenticate!
        current_user.update(avatar: params[:user][:avatar])
        present current_user, with: ::Entities::User
      end

      add_desc "更新用户check时间"
      put :checked_at do
        authenticate!
        c_time = Time.now
        current_user.update(checked_at: c_time)
        present c_time
      end

      add_desc "获取用户动态"
      params do
        requires :user_id, desc: "用户id"
        optional :last_id, desc: "last id"
      end
      get "/:user_id/timeline", requirements: { user_id: /[0-9]*/ } do
        opts = {feeder_id: params[:user_id].to_i, per_page: 10}
        opts[:last_id] = params[:last_id] if params[:last_id].present?
        feeds = MD::Feed.profile.search_feeds_for(nil, opts).to_a
        showed_feeds = feeds.first(10).map(&:pretty_json)
        present showed_feeds
      end

    end

  end
end
