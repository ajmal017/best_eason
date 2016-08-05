class Admin::FeedCategoriesController < Admin::ApplicationController
  def index
    @page_title = "Feed类型管理"
    @feed_categories = ::MD::FeedCategory.all

    if params[:time_rule] == "now"
      @feed_categories = @feed_categories.where(:time_rule.in => MD::FeedRule::TimeRule.get_rule)
    elsif params[:time_rule] == "null"
      @feed_categories = @feed_categories.where(time_rule: [])
    elsif params[:time_rule].present?
      @feed_categories = @feed_categories.where(time_rule: params[:time_rule].to_i)
    end

    @feed_categories = @feed_categories.where(ttl_rule:  params[:ttl_rule].to_i) if params[:ttl_rule].present?
    @feed_categories = @feed_categories.paginate(per_page: 500)
  end


  def new
    @page_title = "添加Feed类型"
    @feed_category = ::MD::FeedCategory.new
  end

  def create
    @page_title = "添加Feed类型"
    @feed_category = ::MD::FeedCategory.new(feed_category_params)
    if @feed_category.save
      redirect_to admin_md_feed_categories_path, notice: "添加成功"
    else
      render :action => :new 
    end
  end

  def edit
    @page_title = "修改Feed类型"
    @feed_category = ::MD::FeedCategory.find(params[:id])
  end

  def update
    @page_title = "修改Feed类型"
    @feed_category = ::MD::FeedCategory.find(params[:id])
    
    if @feed_category.update(feed_category_params)
      redirect_to admin_md_feed_categories_path, notice: "修改成功"
    else
      render :action => :edit
    end
  end

  def destroy
    @feed_category = ::MD::FeedCategory.find(params[:id])
    @feed_category.destroy
    redirect_to(admin_md_feed_categories_path, notice: "删除成功")
  end


  private

  def feed_category_params
    params.require(:feed_category).permit(:name, :weight, :recommend_category, :feed_type, :ttl_rule, time_rule: [])    
  end

end
