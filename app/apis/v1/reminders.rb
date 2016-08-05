module V1
  class Reminders < Grape::API

    resource :reminders, desc: "提醒相关" do

      before do
        authenticate!
      end

      add_desc "修改股票提醒设置(如果需要取消设置请将值设为-1)", entity: ::Entities::StockReminder
      params do
        requires :reminder, type: Hash, default: {} do
          optional :up, type: Float, desc: "股票上涨到某值"
          optional :down, type: Float, desc: "股票下跌到某值"
          optional :scale, type: Float, desc: "股票涨跌比例"
        end
      end
      put "stocks/:stock_id", requirements: {stock_id: /[0-9]*/ } do

        @stock = BaseStock.find(params[:stock_id])
        params[:reminder].each do |k, v|

          sr = StockReminder.find_or_initialize_by(user_id: current_user.id, stock_id: @stock.id, reminder_type: k.to_s)

          if v.to_i == -1
            sr.destroy
          else
            sr.reminder_value = v
            sr.save
          end

        end

        present current_user.stock_reminders.by_stock_result(@stock.id)

      end

      add_desc "获取某股票提醒"
      get "stocks/:stock_id", requirements: {stock_id: /[0-9]*/ } do
        @stock = BaseStock.find(params[:stock_id])
        present current_user.stock_reminders.by_stock_result(@stock.id)
      end

      add_desc "获取我的所有股价提醒", entity: ::Entities::StockReminder
      get "stocks" do
        present current_user.stock_reminders, with: ::Entities::StockReminder
      end

    end

  end
end
