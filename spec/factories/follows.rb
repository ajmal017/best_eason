
FactoryGirl.define do
  factory :follow do |f|
    f.follower {|follower| follower.association(:user)}

    factory :basket_follow do |bf|
      bf.followable {|followable| followable.association(:basket)}
    end
  end
end