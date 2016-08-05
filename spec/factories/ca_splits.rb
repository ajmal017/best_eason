# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ca_split do
    symbol 'AAPL'
    factor '2:1'
  end
end
