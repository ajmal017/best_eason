class SmsContentController < ApplicationController
  def open_callback
    @sms_content = SmsContent.new(phone: params[:phone], msg_content: params[:msgContent].force_encoding("gbk").encode("utf-8"), sp_number: params[:spNumber])
    if @sms_content.save
      render plain: "success submit", status: 201
    else
      render plain: "fail submit", status: 404
    end
  end
end
