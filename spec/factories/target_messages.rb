# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :target_message do
    content "MyText"
    target "MyString"
  end
end
