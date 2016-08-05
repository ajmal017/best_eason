# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :entry do
    feed_id 1
    title "MyString"
    url "MyString"
    content "MyText"
    published_date "2015-01-15 13:31:53"
    up_votes_count 1
    down_votes_count 1
    comments_count 1
  end
end
