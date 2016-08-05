class Admin::TargetMessagesController < Admin::ApplicationController
  before_action :find_target_message, only: [:update, :edit,:show]

  def new
    @target_message = TargetMessage.new
  end

  def edit
    @page_title = "编辑私信"
  end

  def show
    @page_title = "查看私信详情"
    @all_counter = @target_message.target_counter
    @succ_counter = @target_message.r_succ_counter.value
    @fail_counter = @target_message.r_fail_counter.value

    respond_to do |format|
        format.html
        format.json { render json: {all_counter: @all_counter, succ_counter: @succ_counter, fail_counter: @fail_counter}.to_json }
    end
  end

  def create
    @target_message = TargetMessage.new(content: params[:target_message][:content], target: params[:target_message][:target].split(/\r?\n|,/).join(","))
    if @target_message.save
      Resque.enqueue(MessageAddWorker, @target_message.id)
      redirect_to admin_target_message_path(@target_message)
    else
      render "new"
    end
  end

  def update
    @page_title = "修改私信"
    if @target_message.update(target_message_params)
      redirect_to admin_target_message_path(@target_message)
    else
      render action: :edit
    end
  end

  def index
    @target_messages = TargetMessage.order("id desc")
    @paginated_target_messages = @target_messages.paginate(page: params[:page] || 1, per_page: params[:per_page] || 30)
  end

  private

  def target_message_params
    params.require(:target_message).permit(:content, :target)
  end

  def find_target_message
    @target_message = TargetMessage.find(params[:id])
  end

end
