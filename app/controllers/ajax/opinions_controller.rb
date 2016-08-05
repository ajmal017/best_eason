class Ajax::OpinionsController < Ajax::ApplicationController
  before_filter :authenticate_user!, only: [:create]
  before_action :find_opinionable

  def create
    Opinion.set_opinion(params[:opinion], @opinionable, current_user.id)
    render json: @opinionable.reload.opinions_datas
  end

  def datas
    datas  = {logined: current_user.present?, up: Opinion.setted_up?(@opinionable, current_user.try(:id)),
              down: Opinion.setted_down?(@opinionable, current_user.try(:id))}
    datas.merge!(@opinionable.opinions_datas)
    render json: datas
  end

  private

  def find_opinionable
    render json: {error: true} and return unless Opinion::WHITE_TYPES.include?(params[:opinionable_type])

    @opinionable = params[:opinionable_type].constantize.find(params[:opinionable_id])
  end

end