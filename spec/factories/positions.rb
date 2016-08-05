# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :position do
    instance_id { SecureRandom.uuid }
    base_stock_id 2
    basket_id 1
    shares 2
  end
end
