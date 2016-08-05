# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :exec_detail do
    exec_id { Faker::Lorem.characters(8) }
    contract_id 1234
    avg_price 12.2
    shares 200
    stock_id 2
    user_id 2
    processed false
  end
end
