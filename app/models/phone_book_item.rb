class PhoneBookItem < ActiveRecord::Base
  belongs_to :user
  belongs_to :phone_book, counter_cache: :items_count
  belongs_to :caishuo_user, class_name: 'User', foreign_key: :caishuo_id
end
