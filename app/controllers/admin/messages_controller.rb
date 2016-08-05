class Admin::MessagesController < Admin::ApplicationController
  before_action :get_sender_user,:get_receiver_user, only: [:index]
  def index
  	@params = params[:q]||{}
  	@page_title = "消息列表"
	  @q = Message.includes(:sender, :receiver).search(params[:q])
    @messages = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end

  def ajax_del_message
    params[:ids].split(",").each{|id|
      m = Message.find(id)
      m.soft_delete(m.user_talk_id)
      m.soft_delete(m.subscriber_talk_id)
      m.destroy
    }
    render text: "ok"
  end

private
  def get_sender_user
  	@sender_user = params[:q].present? && params[:q][:sender_id_eq].present? ? User.where(id: params[:q][:sender_id_eq]).pluck(:id, :username).flatten : []
  end

  def get_receiver_user
    @receiver_user = params[:q].present? && params[:q][:receiver_id_eq].present? ? User.where(id: params[:q][:receiver_id_eq]).pluck(:id, :username).flatten : []
  end
end