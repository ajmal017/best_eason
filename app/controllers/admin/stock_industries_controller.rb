class Admin::StockIndustriesController < Admin::ApplicationController
  before_action :set_stock_industry, only: [:show, :edit, :update, :destroy]

  def index
    @q = StockIndustry.search(params[:q])
    @stock_industries = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @stock_industry = StockIndustry.new
  end

  def edit
  end

  def create
    @stock_industry = StockIndustry.new(stock_industry_params)

    if @stock_industry.save
      redirect_to [:admin, @stock_industry], notice: 'Stock industry was successfully created.'
    else
      render :new
    end
  end

  def update
    if @stock_industry.update(stock_industry_params)
      redirect_to [:admin, @stock_industry], notice: 'Stock industry was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @stock_industry.destroy
    redirect_to admin_stock_industries_url, notice: 'Stock industry was successfully destroyed.'
  end

  private
  
  def set_stock_industry
    @stock_industry = StockIndustry.find(params[:id])
  end

  def stock_industry_params
    params.require(:stock_industry).permit(:base_stock_id, :first_industry_code, :first_industry_name, :second_industry_code, :second_industry_name, :cancel_date, :sector_code)
  end
end
