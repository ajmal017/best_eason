# Read about factories at https://github.com/thoughtbot/factory_girl
require 'faker'

FactoryGirl.define do
  factory :order_detail do
    association :order
    association :stock
    instance_id { SecureRandom.uuid }
    symbol { Faker::Lorem.characters(4) }
    user_id 2
    basket_id 2
    est_shares 3
    
    factory :order_detail_with_stock do
      # before(:create) do |instance|
#         stock = create(:stock)
#         instance.stock = stock
#end
    end
  end
end
