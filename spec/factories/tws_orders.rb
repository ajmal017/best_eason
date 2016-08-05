# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tws_order do
    exchange "MyString"
    symbol "MyString"
    contract_id 1
    account_name "MyString"
    avg_price "9.99"
    cum_quantity 1
    price "9.99"
    shares 1
    side "MyString"
    time "MyString"
    ib_order_id 1
  end
end
