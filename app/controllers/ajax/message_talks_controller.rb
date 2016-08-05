class Ajax::MessageTalksController < Ajax::ApplicationController
  before_filter :authenticate_user!, only: [:index, :show, :destroy, :mark_read]
  skip_before_action :require_xhr?, only: [:destroy]
  
  before_action :load_message_talk, only: [:show, :destroy]

  #after_action :mark_message_as_read, only: [:show]

  def show
    @messages = @message_talk.messages.where("id < ?", params[:last_msg_id]).includes(:sender).paginate(page: params[:page] || 1, per_page: 5)
  end

  def destroy
    @message_talk.clear

    redirect_to messages_path
  end

  def counter
    @counters = MessageTalk.where(id: params[:ids]).map do |talk|
      [talk.id, talk.messages.where(receiver_id: current_user.id).unread.count]
    end.to_h
  end

  # 批量标记私信已读
  def mark_read
    MessageTalk.where(id: params[:ids]).each do |talk|
      talk.messages.where(receiver_id: current_user.id).update_all(read: true)
    end
    Message.adjust_counter!(current_user.id)

    render json: {result: true}
  end

  def mark_message_as_read
    @messages.where(receiver_id: current_user.id).update_all(read: true)

    Message.adjust_counter!(current_user.id)
  end

  private

  def load_message_talk
    @message_talk = MessageTalk.find(params[:id])
  end
end
