class Admin::ActiveDocksController < Admin::ApplicationController

  before_action :get_active, only: [:edit, :show, :destroy, :update]

  def index
    @active_docks = ActiveDock.order("id desc").paginate(page: params[:page] || 1, per_page: 20)
  end

  def new
    @active_dock = ActiveDock.new
  end

  def show
  end

  def create
    @active_dock = ActiveDock.new(active_dock_params)
    if @active_dock.save
      redirect_to admin_active_docks_path, notice: "添加成功！"
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @active_dock.update_attributes(active_dock_params)
      redirect_to admin_active_docks_path, notice: "修改成功！"
    else
      render :edit
    end
  end

  def destroy
    @active_dock.destroy
    redirect_to admin_active_docks_path, notice: "删除成功！"
  end

  private
    def active_dock_params
      params.require(:active_dock).permit(:name, :description, :dock_date, :short_id)
    end

    def get_active
      @active_dock ||= ActiveDock.find(params[:id])
    end

end
