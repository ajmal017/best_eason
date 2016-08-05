# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :basket do |b|
    title { Faker::Lorem.sentence }
    b.author {|author| author.association(:user)}
    type "Basket::Normal"

    factory :basket_with_stocks do
      after(:create) do |basket|
        create_list(:basket_stock, 5, basket: basket, weight: 0.2)
      end
    end

    factory :basket_with_multi_area_stocks do
      after(:create) do |basket|
        create_list(:basket_stock, 1, basket: basket, weight: 0.3)
        create_list(:basket_stock_of_hk, 1, basket: basket, weight: 0.7)
      end
    end
    
    factory :basket_with_appl_and_yhoo do
      after(:create) do |basket|
        basket.basket_stocks << create(:basket_stock_with_appl, basket: basket, weight: 0.5)
        basket.basket_stocks << create(:basket_stock_with_yhoo, basket: basket, weight: 0.5)
      end
    end
  end

  factory :normal_basket, :class => 'Basket::Normal' do |b|
    title { Faker::Lorem.sentence }
    b.author {|author| author.association(:user)}
    type "Basket::Normal"

    factory :basket_with_one_stock do
      after(:create) do |basket|
        create_list(:basket_stock, 1, basket: basket, weight: 1)
      end
    end
  end
end
