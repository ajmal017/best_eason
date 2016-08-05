class Admin::ChannelCodesController < Admin::ApplicationController
  def index
    @page_title = "推广渠道管理"
    @q = ChannelCode.search(params[:q])
    @channel_codes = @q.result
    params[:start_date] ||= Date.today.to_s(:db)
    params[:end_date] ||= Date.today.to_s(:db)
    @statistics = ChannelLog.statistics(@channel_codes.map(&:id), params[:start_date], params[:end_date])
  end


  def new
    @page_title = "添加推广渠道"
    @channel_code = ChannelCode.new
  end

  def create
    @page_title = "添加推广渠道"
    @channel_code = ChannelCode.new(channel_code_params)

    if @channel_code.save
      redirect_to admin_channel_codes_path, notice: "添加成功"
    else
      render :action => :new 
    end
  end

  def edit
    @page_title = "修改推广渠道"
    @channel_code = ChannelCode.find(params[:id])
  end

  def update
    @page_title = "修改推广渠道"
    @channel_code = ChannelCode.find(params[:id])
    
    if @channel_code.update(channel_code_params)
      redirect_to admin_channel_codes_path, notice: "修改成功"
    else
      render :action => :edit
    end
  end

  def destroy
    @channel_code = ChannelCode.find(params[:id])
    @channel_code.destroy
    redirect_to(admin_channel_codes_path, notice: "删除成功")
  end

  def notice
    emails = ["zhangxiaobin@caishuo.com", "wangchangming@caishuo.com", "changqing@caishuo.com"]
    @channel_codes = ChannelCode.order("id desc").pluck(:code)
    email_body = @channel_codes * "\n"
    if Rails.env.production?
      Caishuo::Utils::Email.deliver(emails, email_body, "APP渠道汇总: #{Time.now.to_s(:db)}", nil, "#{@current_admin_staffer.fullname}-系统01 <system01@caishuo.com>")
    end
    redirect_to(admin_channel_codes_path, notice: "通知邮件已发送")
  end

  private

  def channel_code_params
    params.require(:channel_code).permit(:code, :status, :media, :ad_type)    
  end

end
