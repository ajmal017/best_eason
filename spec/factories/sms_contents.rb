# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sms_content do
    phone "MyString"
    msg_content "MyText"
    sp_number "MyString"
  end
end
