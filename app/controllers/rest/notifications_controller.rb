class Rest::NotificationsController < Rest::BaseController
  before_action :validate_params

  def create
    @user = User.find(params[:user_id])
    send(params[:type])
    present true
  end

private
  # 调用接口后异步执行
  def sms
    RestClient.api.tool.sms(@user.mobile, params[:content]) if Rails.env.production?
  end

  # 放入mp等待消费
  def push
    JpushPublisher.publish({type: "alias", alias: @user.id, content: params[:content]})
  end

  # resuqe异步执行
  def globle
    Resque.enqueue(SendGlobleNotificationWorker, @user.id, params[:content], params[:time])
  end

  def receive_scope
    %w[sms push globle]
  end

  def validate_params
    raise "没有找到指定type" unless receive_scope.include? params[:type]
    requires :content, :user_id
  end

end
