# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contest_cash do
    contest nil
    value "MyString"
    key "MyString"
  end
end
