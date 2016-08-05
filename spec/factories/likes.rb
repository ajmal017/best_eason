
FactoryGirl.define do
  factory :like do |l|
    l.liker {|liker| liker.association(:user)}

    factory :comment_like do |cl|
      cl.likeable {|likeable| likeable.association(:comment)}
    end
  end
end