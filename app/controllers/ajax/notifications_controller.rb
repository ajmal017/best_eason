class Ajax::NotificationsController < Ajax::ApplicationController
  after_action :adjust_counter, only: [:mark_read]
  before_action :load_notification, only: [:destroy, :delete]

  def mark_read
    current_user.notifications.where(:id => params[:ids]).update_all(read: true)
    render :text => "ok"
  end

  def destroy
    if @notification.user_id == current_user.id
      @notification.destroy
      render json: {result: true}
    else
      render json: {result: false}
    end
  end

  def delete
    if @notification.user_id == current_user.id
      @notification.destroy
      render json: {status: 0}
    else
      render json: {status: 1, msg: "删除失败"}
    end
  end

  private

  def load_notification
    @notification = Notification::Base.find_by(id: params[:id])
  end

  def adjust_counter
    case params[:type]
    when 'mention'
      Notification::Mention.adjust_counter!(current_user)
    when 'system'
      Notification::System.adjust_counter!(current_user)
    when 'reminder'
      Notification::Position.adjust_counter!(current_user)
      Notification::StockReminder.adjust_counter!(current_user)
    else
      Notification::Comment.adjust_counter!(current_user)
      Notification::Like.adjust_counter!(current_user)
    end
  end
end
