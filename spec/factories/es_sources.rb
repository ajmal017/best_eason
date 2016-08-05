# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :es_source, :class => 'ES::Source' do
    name "MyString"
    url "MyString"
  end
end
