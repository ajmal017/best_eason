# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :profile do
    biography "MyString"
    orientation 1
    concern 1
    profession 1
    duration 1
  end
end
