# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ib_order_sequence do
    ib_order_id 1
    sequence 1
  end
end
