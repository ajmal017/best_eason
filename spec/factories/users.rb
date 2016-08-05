require 'faker'

FactoryGirl.define do
  factory :user, class: 'User' do
    id 1
    username { Faker::Lorem.characters(8) }
    email { "#{username}@example.com".downcase }
    is_company_user false
    password "88888888"
    password_confirmation "88888888"

    factory :common_user do
      is_company_user false
    end

    factory :api_tokens, class: 'ApiToken' do
    end
    
    factory :company_user do
      is_company_user true
    end
    
    factory :binding_user, class: 'User' do
      username "binding_user"
      available false
    end
  end
end
