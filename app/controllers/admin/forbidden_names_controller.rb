class Admin::ForbiddenNamesController < Admin::ApplicationController
  def index
    @names = ForbiddenName.order(:id).paginate(page: params[:page]||1, per_page: 20).to_a
  end

  def create
    @forbidden_name = ForbiddenName.create(word: params[:word].to_s.strip)
    notice = @forbidden_name.valid? ? "创建成功" : "已存在"
    redirect_to admin_forbidden_names_path, notice: notice
  end

  def destroy
    forbidden_name = ForbiddenName.find(params[:id])
    forbidden_name.destroy if forbidden_name
    redirect_to admin_forbidden_names_path, notice: "删除成功"
  end
end