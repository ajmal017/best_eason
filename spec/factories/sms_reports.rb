# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sms_report do
    plat_form "MyString"
    f_unikey "MyString"
    f_org_addr "MyString"
    f_dest_addr "MyString"
    f_submit_time "MyString"
    f_fee_terminal "MyString"
    f_service_u_p_i_d "MyString"
    f_report_code "MyString"
    f_link_i_d "MyString"
    f_ack_status "MyString"
  end
end
