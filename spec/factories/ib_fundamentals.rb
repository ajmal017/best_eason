# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ib_fundamental do
    exchange "MyString"
    symbol "MyString"
    current_xml "MyText"
    forecast_xml "MyText"
  end
end
