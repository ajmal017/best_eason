class Admin::P2pStrategiesController < Admin::ApplicationController
  before_action :get_p2p_strategy, only: [:edit, :update]

  def index
    @page_title = "P2P产品策略列表"
    @p2p_strategies = P2pStrategy.all.paginate(page: params[:page]||1, per_page: 10).to_a
  end

  def new
    @page_title = "新建P2P产品策略"
    @p2p_strategy = P2pStrategy.new
  end

  def create
    @p2p_strategy = P2pStrategy.new permit
    @p2p_strategy.staffer = current_admin_staffer

    stock = BaseStock.find(params[:p2p_strategy][:mentionable_id])
    @p2p_strategy.mentionable = stock

    if @p2p_strategy.save
      redirect_to admin_p2p_strategies_path
    else
      render :new
    end
  end

  def edit
    @page_title = "修改P2P产品策略"
  end

  def update
    @p2p_strategy.assign_attributes(permit)

    if params[:p2p_strategy][:mentionable_id].present?
      stock = BaseStock.find(params[:p2p_strategy][:mentionable_id])
      @p2p_strategy.mentionable = stock
    end

    if @p2p_strategy.save
      redirect_to admin_p2p_strategies_path
    else
      render :edit
    end
  end

  private
  def permit
    params[:p2p_strategy].permit(:weight, :change_type, :base_type)
  end

  def get_p2p_strategy
    @p2p_strategy = P2pStrategy.find(params[:id])
  end
end
