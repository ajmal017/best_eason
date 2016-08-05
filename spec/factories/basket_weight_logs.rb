
FactoryGirl.define do
  factory :basket_weight_log do |bwl|
    bwl.stock {|stock| stock.association(:base_stock) }
    bwl.basket {|basket| basket.association(:basket) }
  end
end