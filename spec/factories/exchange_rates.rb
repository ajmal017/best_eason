# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :exchange_rate do
    value "9.99"
    currency "MyString"
    account_name "MyString"
  end
end
