# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :stock_info do
    description "MyText"
    site "MyString"
    telephone "MyString"
    profession "MyText"
  end
end
