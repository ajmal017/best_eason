# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :order, class: 'OrderBuy' do
    basket_id 2
    user_id 1
    est_cost 2
    basket_mount 2
    status "confirmed"

    factory :unconfirmed_order do
      status "unconfirmed"
    end
  end
end
