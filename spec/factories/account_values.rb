# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :account_value do
    user_id 1
    broker_user_id "MyString"
    key "MyString"
    currency "MyString"
    value "9.99"
    user_binding_id 1
  end
end
