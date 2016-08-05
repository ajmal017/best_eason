
FactoryGirl.define do
  factory :comment do |c|
    c.commenter {|commenter| commenter.association(:user)}
    content { Faker::Lorem.sentence }

    factory :comment_basket do |cc|
      c.commentable {|commentable| commentable.association(:basket) }
    end

    factory :comment_comment do |cc|
      cc.commentable {|commentable| commentable.association(:comment) }
    end
  end
end