# 每天早10点，下午5点检查区间内是否有发起的组合审核，如有则发送邮件给指定人员
class BasketAuditing
  @queue = :basket_auditing
  
  def self.perform
    return false unless [10, 17].include?(Time.now.hour)

    adjust_hours = Time.now.hour == 10 ? -8.hours : 10.hours
    audit_start_time = Date.today + adjust_hours
    audit_end_time = Time.now

    audits_count = BasketAudit.auditing.where("created_at > ? and created_at <= ?", audit_start_time, audit_end_time).count
    return false if audits_count == 0
    
    search_params = {basket_audits_created_at_gteq: audit_start_time.to_s(:db), basket_audits_created_at_lteq: audit_end_time.to_s(:db), basket_audits_state_eq: BasketAudit::STATE_DESC["审核中"]}
    a_link = Setting.host + "/admin/baskets?" + {q: search_params}.to_query
    html = "<a href='#{a_link}'>点击查看 #{audit_start_time} - #{audit_end_time}之间新增审核</a>"
    Setting.basket_auditers.emails.each do |email|
      Caishuo::Utils::Email.deliver(email, nil, "新增需要审核的组合", html)
    end
    
  end
end