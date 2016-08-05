# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :survey do
    q1_1 1
    q1_2 "MyString"
    q2 false
    q3_1 1
    q3_2 1
    q3_3 1
    q3_4 1
    q3_5 "MyString"
    q4 "MyText"
    q5 "MyText"
    user_name "MyString"
    user_gender "MyString"
    user_phone "MyString"
  end
end
