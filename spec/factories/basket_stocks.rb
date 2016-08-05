require "faker"

FactoryGirl.define do
  factory :basket_stock do |bs|
    weight 1
    association :basket
    bs.stock {|stock| stock.association(:base_stock) }
  end
  
  factory :basket_stock_with_appl, class: 'BasketStock'  do |bs|
    weight 1
    association :basket
    bs.stock {|stock| stock.association(:base_stock_appl) }
  end
  
  factory :basket_stock_with_yhoo, class: 'BasketStock'  do |bs|
    weight 1
    association :basket
    bs.stock {|stock| stock.association(:base_stock_yhoo) }
  end

  factory :basket_stock_of_hk, class: 'BasketStock' do |bs|
    weight 1
    association :basket
    bs.stock {|stock| stock.association(:hk_stock) }
  end
end