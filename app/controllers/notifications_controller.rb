class NotificationsController < ApplicationController
  before_filter :authenticate_user!

  before_action :load_counter, only: [:comment, :system, :mention, :reminder]
  before_action :unread_count, only: [:system, :stock, :position, :reminder]

  def index
    @notifications = current_user.notifications.order(id: :desc).paginate(page: params[:page], per_page: 20)
  end

  def destroy
    @notification = current_user.notifications.find(params[:id])
    @notification.destroy
  end

  def clear
    current_user.notifications.delete_all
  end

  def comment
    # page超过最大页之后取最大页
    total_entries = current_user.notifications.any_of_comment_or_like.displayable.count

    @notifications = current_user.notifications.any_of_comment_or_like.displayable.sort_desc
      .includes(:user, :triggered_user, :targetable, :originable, :mentionable).paginate(page: adjusted_page(total_entries, 10), per_page: params[:per_page] || 10)
    respond_to do |format|
      format.html
      format.json {
        render json: {lists: @notifications.map(&:as_json), pages: @notifications.total_pages, index: @notifications.current_page, unreadNumber: @counter.comment_with_like.to_i}
      }
    end
  end

  def system
    @notifications = current_user.notifications.system.sort_desc.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
  end

  def reminder
    @reminders = current_user.notifications.includes(:mentionable).where({type: ["Notification::StockReminder", "Notification::Position"]}).order('created_at DESC').paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
  end

  def mention
    total_entries = Notification::Mention.where(user_id: current_user.id).count

    @notifications = Notification::Mention.where(user_id: current_user.id).sort_desc
      .includes(:user, :triggered_user, :targetable, :originable, :mentionable).paginate(page: adjusted_page(total_entries), per_page: params[:per_page] || 10)

    respond_to do |format|
      format.html
      format.json{
        render json: {lists: @notifications.map(&:as_json), pages: @notifications.total_pages, index: @notifications.current_page}
      }
    end
  end

  private
  def mark_all_as_read
    current_user.notifications.unread.update(read: true)
  end

  def load_counter
    @counter = Counter.find_by(user_id: current_user.id)
  end

  def unread_count
    @unread_systems_count = current_user.notifications.system.unread.count
    @unread_reminders_count = current_user.notifications.stock.unread.count + current_user.notifications.position.unread.count
  end

  def adjusted_page(total_entries, per_page = 10)
    return 1 if total_entries.zero? || params[:page].blank?
    (params[:page].to_i * per_page > total_entries) ? (total_entries.fdiv(per_page)).ceil : params[:page]
  end
end
