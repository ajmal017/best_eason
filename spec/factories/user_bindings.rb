require 'faker'

FactoryGirl.define do
  factory :user_binding do
    association :user
    broker_user_id "DU186928"
    broker_id 2
    available false
    count 1
  end
end