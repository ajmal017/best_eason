# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contest do
    status 1
    name "MyString"
    start_at "2015-06-04 00:54:25"
    end_at "2015-06-04 00:54:25"
    broker_id 1
    users_count 1
    total_invest "9.99"
  end
end
