# Read about factories at https://github.com/thoughtbot/factory_girl
require 'faker'

FactoryGirl.define do
  factory :admin_staffer, :class => 'Admin::Staffer' do
    username { Faker::Lorem.characters(8) }
    fullname { Faker::Lorem.characters(8) }
    email { "#{username}@example.com".downcase }
    password "88888888"
    password_confirmation "88888888"
    confirmed_at { 7.days.ago }
  end
end
