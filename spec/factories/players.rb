# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :player do
    user_id 1
    contest_id 1
    original_money "MyString"
    status 1
    trading_account_id 1
  end
end
