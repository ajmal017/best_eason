class Admin::StockComponentsController < Admin::ApplicationController
  before_action :set_stock_component, only: [:show, :edit, :update, :destroy]

  def index
    @q = StockComponent.includes(:base_stock).search(params[:q])
    @stock_components = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @stock_component = StockComponent.new
  end

  def edit
  end

  def create
    @stock_component = StockComponent.new(stock_component_params)

    if @stock_component.save
      redirect_to [:admin, @stock_component], notice: 'Stock component was successfully created.'
    else
      render :new
    end
  end

  def update
    if @stock_component.update(stock_component_params)
      redirect_to [:admin, @stock_component], notice: 'Stock component was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @stock_component.destroy
    redirect_to admin_stock_components_url, notice: 'Stock component was successfully destroyed.'
  end

  private
  
  def set_stock_component
    @stock_component = StockComponent.find(params[:id])
  end

  def stock_component_params
    params.require(:stock_component).permit(:base_stock_id, :inner_code, :cs_code, :name)
  end
end
