# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :stock_change do
    from_id 1
    to_id 1
    from_symbol "MyString"
    to_symbol "MyString"
    date "2015-03-27"
    factor "MyString"
  end
end
