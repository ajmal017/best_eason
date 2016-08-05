class Admin::JyIndustriesController < Admin::ApplicationController
  before_action :set_jy_industry, only: [:show, :edit, :update, :destroy]

  def index
    @q = JyIndustry.search(params[:q])
    @jy_industries = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @jy_industry = JyIndustry.new
  end

  def edit
  end

  def create
    @jy_industry = JyIndustry.new(jy_industry_params)

    if @jy_industry.save
      redirect_to [:admin, @jy_industry], notice: 'Jy industry was successfully created.'
    else
      render :new
    end
  end

  def update
    if @jy_industry.update(jy_industry_params)
      redirect_to [:admin, @jy_industry], notice: 'Jy industry was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @jy_industry.destroy
    redirect_to admin_jy_industries_url, notice: 'Jy industry was successfully destroyed.'
  end

  private
  
  def set_jy_industry
    @jy_industry = JyIndustry.find(params[:id])
  end

  def jy_industry_params
    params.require(:jy_industry).permit(:name, :code, :level)
  end
end
