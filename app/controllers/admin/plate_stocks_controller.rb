class Admin::PlateStocksController < Admin::ApplicationController
  before_action :set_plate_stock, only: [:show, :edit, :update, :destroy]

  def index
    @page_title = "板块股票映射列表页"
    @q = PlateStock.search(params[:q])
    @plate_stocks = @q.result.order(weight: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @plate_stock = PlateStock.new
  end

  def edit
  end

  def create
    @plate_stock = PlateStock.new(plate_stock_params)

    if @plate_stock.save
      redirect_to [:admin, @plate_stock], notice: 'Plate stock was successfully created.'
    else
      render :new
    end
  end

  def update
    if @plate_stock.update(plate_stock_params)
      redirect_to [:admin, @plate_stock], notice: 'Plate stock was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @plate_stock.destroy
    redirect_to admin_plate_stocks_url, notice: 'Plate stock was successfully destroyed.'
  end

  private
  
  def set_plate_stock
    @plate_stock = PlateStock.find(params[:id])
  end

  def plate_stock_params
    params.require(:plate_stock).permit(:plate_id, :base_stock_id, :weight, :start_on, :end_on, :status)
  end
end
