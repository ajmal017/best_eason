class MessagesController < ApplicationController
  before_filter :authenticate_user!
  before_action :set_message, only: [:destroy]
  before_action :set_message_talk, only: [:show]
  before_action :check_permission, only: [:destroy]

  # before_action :load_counter, only: [:index, :show]
  # after_action :mark_message_as_read, only: [:show, :create]
  
  def index
    if params[:user_id].present?
      redirect_to message_path(talked_by(params[:user_id]), from: 'profile') and return
    else
      @talks = MessageTalk.talks_of(current_user.id).paginate(page: params[:page] || 1, per_page: 10)
    end

    @page_title = "私信列表页面"
  end

  def new
    @message = Message.new
  end

  def create
    @message = Message.add(current_user.id, params[:message][:receiver_id], params[:message][:content])
    if @message.valid?
      @talk = MessageTalk.find(params[:talk_id])
      @messages = @talk.messages.where("id > ?", params[:last_msg_id].to_i).order(id: :desc).limit(10)
      mark_message_as_read
    end
  end
  
  def show
    redirect_to messages_path unless @talk.user_id == current_user.id

    @messages = @talk.messages.includes(:sender).desc_id.paginate(page: params[:page] || 1, per_page: params[:per_page] || 5)
    mark_message_as_read
    @page_title = "与#{@talk.try(:subscriber).try(:username)}对话中"
  end

  def destroy
    @message.soft_delete(params[:talk_id])
  end

  private
  
  def set_message
    @message = Message.find(params[:id])
  end

  def set_message_talk
    @talk = MessageTalk.find_by_id(params[:id])
    if @talk.blank?
      redirect_to messages_path
    end
  end

  def check_permission
    redirect_to messages_path unless @message.slice(:sender_id, :receiver_id).values.include? current_user.id
  end

  def mark_message_as_read
    @talk.messages.where(receiver_id: current_user.id).update_all(read: true)
    
    Message.adjust_counter!(current_user.id)
  end

  def load_counter
    @counter || (@counter = Counter.find_by(user_id: current_user.id))
  end

  def talked_by(user_id)
    MessageTalk.fetch_by(current_user.id, user_id)
  end
end
