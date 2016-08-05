# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ib_position do
    user_id 1
    base_stock_id 1
    symbol "MyString"
    contract_id 1
    account_name "MyString"
    position "9.99"
    exchange "MyString"
  end
end
