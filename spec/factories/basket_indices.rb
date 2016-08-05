
FactoryGirl.define do
  factory :basket_index do |bi|
    association :basket
    index 1001
  end
end
