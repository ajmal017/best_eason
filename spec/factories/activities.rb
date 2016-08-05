# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :activity do
    user_id 1
    type ""
    feed_id 1
    followed_user_id 1
    entry_id 1
    content "MyText"
    following_user_id 1
  end
end
