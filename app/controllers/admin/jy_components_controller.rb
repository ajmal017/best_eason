class Admin::JyComponentsController < Admin::ApplicationController
  before_action :set_jy_component, only: [:show, :edit, :update, :destroy]

  def index
    @q = JyComponent.search(params[:q])
    @jy_components = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @jy_component = JyComponent.new
  end

  def edit
  end

  def create
    @jy_component = JyComponent.new(jy_component_params)

    if @jy_component.save
      redirect_to [:admin, @jy_component], notice: 'Jy component was successfully created.'
    else
      render :new
    end
  end

  def update
    if @jy_component.update(jy_component_params)
      redirect_to [:admin, @jy_component], notice: 'Jy component was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @jy_component.destroy
    redirect_to admin_jy_components_url, notice: 'Jy component was successfully destroyed.'
  end

  private
  
  def set_jy_component
    @jy_component = JyComponent.find(params[:id])
  end

  def jy_component_params
    params.require(:jy_component).permit(:begin_date, :l_one_name, :l_one_code, :l_two_name, :l_two_code, :flag)
  end
end
