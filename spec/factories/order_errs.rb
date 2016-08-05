# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :order_err do
    order_id 1
    ib_order_id 1
    symbol "MyString"
    code "MyString"
    message "MyString"
  end
end
