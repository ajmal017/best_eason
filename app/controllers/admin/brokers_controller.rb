class Admin::BrokersController < Admin::ApplicationController
  before_action :load_broker, only: [:edit, :update, :show]

  def index
    @page_title = "交易所列表"
    @q = Broker.search(params)
    @brokers = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: 50).to_a
  end
  
  def show
    @page_title = "查看交易所详情"
  end
  
  def new
    @page_title = "添加交易所列表"
    @broker = Broker.new
  end

  def create
    @page_title = "添加交易所列表"
    @broker = Broker.new(broker_params)
    
    if @broker.save
      redirect_to admin_broker_path(@broker)
    else
      render action: :new
    end
  end

  def edit
    @page_title = "修改交易所列表"
  end

  def update
    @page_title = "修改交易所列表"
    if @broker.update(broker_params)
      redirect_to admin_broker_path(@broker)
    else
      render action: :edit
    end
  end

  def sync_trading_date
    RestClient.trading.broker.sync_trading_date(params[:id])
    redirect_to action: :index
  end

  private

  def broker_params
    params.require(:broker).permit(:name, :cname, :master_account, :market, :status)
  end

  def load_broker
    @broker = Broker.find(params[:id])
  end
end
