# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :commission_report do
    commission "9.99"
    currency "MyString"
    exec_id "MyString"
    realized_pnl "9.99"
    yield_redemption_date "MyString"
  end
end
