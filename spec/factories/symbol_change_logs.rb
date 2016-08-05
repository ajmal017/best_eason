# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :symbol_change_log do
    base_stock_id 1
    field "MyString"
    log "MyString"
    log_type "MyString"
  end
end
