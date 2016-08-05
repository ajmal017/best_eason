module V1
  class Permissions < Grape::API
    resource :permissions, desc: "隐私权限相关" do

      before do
        authenticate!
      end

      add_desc "我的隐私设置", entity: ::Entities::AppPermission
      get :my do
        present current_user.get_app_permission, with: ::Entities::AppPermission
      end

      add_desc "更新我的隐私设置", entity: ::Entities::AppPermission
      params do
        optional :permission, type: Hash, default: {} do
          optional :all, using: ::Entities::AppPermission.documentation
        end
      end
      put :my do
        if current_user.app_permission.nil?
          current_user.create_app_permission(params[:permission].to_hash)
        else
          current_user.app_permission.update_attributes!(params[:permission].to_hash)
        end
        present current_user.get_app_permission, with: ::Entities::AppPermission
      end

    end
  end
end
