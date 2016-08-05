module V1
  class Notifications < Grape::API

    resource :notifications, desc: "通知相关" do
      before do
        authenticate!
      end

      add_desc "通知或消息接口(默认为通知)", entity: ::Entities::Notification
      params do
        optional :type, desc: "通知notification, 消息news", type: String, values: %w[notification news], default: "notification"
        optional :all, using: ::Entities::Paginate.documentation
        optional :last_id, desc: "起始查询通知id", type: Integer
      end
      get do

        @notifications = Notification::Base.send("app_#{params[:type]}_types")
          .includes(:triggered_user, :mentionable, :originable, :targetable)
          .where(user_id: current_user.id)
          .order("id desc")
        @notifications = @notifications.where("id < ?", params[:last_id]) if params[:last_id].present?

        present paginate(@notifications), with: Entities::Notification
      end

      add_desc "删除通知"
      params do
        requires :notification_ids, desc: "通知ids(多个以,间隔)", type: String
      end
      delete :clear do
        @notifications = Notification::Base.where(id: params[:notification_ids].split(","), user_id: current_user.id)
        ids = @notifications.pluck(:id)

        @notifications.destroy_all
        present ids
      end

      add_desc "设置通知为已读"
      params do
        requires :notification_ids, desc: "通知ids(多个以,间隔)", type: String
      end
      put :set_read do
        @notifications = Notification::Base.where(id: params[:notification_ids].split(","), user_id: current_user.id)
        ids = @notifications.pluck(:id)

        @notifications.update_all(read: true)

        # 同步未读数量
        @notifications.map(&:class).uniq.each{|c| c.adjust_counter!(current_user) }

        present ids
      end

      add_desc "设置所有通知或消息为已读"
      params do
        requires :type, desc: "通知notification, 消息news", type: String, values: %w[notification news]
      end
      put :set_read_all do
        @notifications = Notification::Base.send("app_#{params[:type]}_types").where(user_id: current_user.id)

        @notifications.update_all(read: true)

        # 同步未读数量
        @notifications.map(&:class).uniq.each{|c| c.adjust_counter!(current_user) }

        present true
      end

      add_desc "消息数量"
      params do
        optional :type, desc: "通知notification, 消息news", type: String, values: %w[notification news], default: "notification"
      end
      get :count do
        counter = Counter.find_by(user_id: current_user.id)
        count =
          if counter.present?
            case params[:type]
            when "notification"
              counter.unread_system_count + counter.unread_position_count + counter.unread_stock_reminder_count
            when "news"
              counter.unread_comment_count + counter.unread_like_count + counter.unread_mention_count
            end
          else
            0
          end
        present count
      end

    end

  end
end
