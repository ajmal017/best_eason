# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :portfolio do
    base_stock_id 1
    user_id 1
    position 1
    currency "MyString"
    symbol "MyString"
    contract_id 1
    market_price "9.99"
    market_value "9.99"
    average_cost "9.99"
    unrealized_pnl "9.99"
    realized_pnl "9.99"
    account_name "MyString"
  end
end
