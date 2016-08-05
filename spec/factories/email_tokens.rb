# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :email_token do
    email "MyString"
    confirmation_token "MyString"
    confirmed_at "2015-04-02 18:38:24"
    confirmation_sent_at "2015-04-02 18:38:24"
  end
end
