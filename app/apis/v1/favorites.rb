module V1
  class Favorites < Grape::API
    resource :favorites, desc: "收藏相关" do

      add_desc "根据当前用户返回收藏列表", entity: ::Entities::Follow
      params do
        optional :all, using: ::Entities::Paginate.documentation
      end
      get do
        authenticate!
        favorites = Follow::Base.favorites.by_user(current_user.id).sort
        present paginate(favorites), with: ::Entities::Follow
      end

      add_desc "删除收藏, 返回成功删除的ids"
      params do
        optional :ids, desc: "收藏ids，多个以,分割", type: String
        optional :favorite, desc: "收藏对象", type: Hash do
          requires :id, desc: "收藏对象id", type: String
          requires :type, desc: "收藏对象类型", type: String, values: ::Follow::Base::FAVORITE_TYPES
        end

        exactly_one_of :ids, :favorite
      end
      delete do
        authenticate!

        if params[:ids].present?
          favorites = Follow::Base.by_user(current_user.id)
          favorites = favorites.where(id: params[:ids].split(",")) if params[:ids].present?
          ids = favorites.pluck(:id)
          favorites.delete_all
          present ids
        elsif params[:favorite].present?
          record = DbAdapter::Base.new(::Follow::Base::FAVORITE_TYPES_KLASS[params[:favorite][:type]]).find(params[:favorite][:id])
          current_user.remove_favorite(record)
        end

      end

      add_desc "添加收藏", entity: ::Entities::Follow
      params do
        requires :id, desc: "id", type: String
        requires :type, desc: "类型", type: String, values: ::Follow::Base::FAVORITE_TYPES
      end
      post do
        authenticate!
        record = DbAdapter::Base.new(::Follow::Base::FAVORITE_TYPES_KLASS[params[:type]]).find(params[:id])
        result = current_user.add_favorite(record)
        present result, with: ::Entities::Follow
      end

    end
  end
end
