# Read about factories at https://github.com/thoughtbot/factory_girl
require 'faker'

FactoryGirl.define do
  factory :api_token do
    access_token "123456"
    sn_code "123456"
    expires_at Time.now+1.years
    user_id 1
    active true
  end
end
