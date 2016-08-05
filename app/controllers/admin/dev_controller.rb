class Admin::DevController < Admin::ApplicationController

  def templates
    @page_title = "后台功能开发规范"
    @key = params[:id].try(:to_sym) || :global
    @template = AdminTemplate::CATEGORIES.keys.include?(@key) ? AdminTemplate::CATEGORIES[@key][:template] : :global
  end

  def ajax_dialog
    render text: "I am from AJAX"
  end

  def test_email
    @page_title = "邮件测试"
    render and return if params[:email].blank?
    if params[:url].present?
      body = open(params[:url]).try(:read)

      Caishuo::Utils::Email.deliver(params[:email], nil,  @page_title, body)
    else
      Caishuo::Utils::Email.deliver(params[:email], params[:body], @page_title)
    end
    
    redirect_to action: :test_email, notice: "发送成功"
  end


  def test_feed
    @page_title = "Feed测试"
  end

end