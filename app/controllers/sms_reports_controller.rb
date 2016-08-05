class SmsReportsController < ApplicationController
  def get_status
    @sms_report = SmsReport.new(plat_form: params[:PlatForm], f_unikey: params[:FUnikey], f_org_addr: params[:FOrgAddr],
    f_dest_addr: params[:FDestAddr], f_submit_time: params[:FSubmitTime], f_fee_terminal: params[:FFeeTerminal],
    f_service_u_p_i_d: params[:FServiceUPID], f_report_code: params[:FReportCode], f_link_i_d: params[:FLinkID],
    f_ack_status: params[:FAckStatus])

    if @sms_report.save
      render plain: "success submit", status: 201
    else
      render plain: "fail submit", status: 404
    end
  end
end
