# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :order_log do
    user_id 1
    order_id 1
    ib_order_id 1
    instance_id "MyString"
    base_stock_id 1
    sequence 1
    filled 1
    cost "9.99"
  end
end
