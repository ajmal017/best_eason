class Favorite < ActiveRecord::Base
  belongs_to :user
  belongs_to :favorable, polymorphic: true, counter_cache: 'favorites_count'

  validates_presence_of :user_id

  # TODO 没有在mesage找到favorable_type
  #validates :favorable_id, uniqueness: {scope: [:user_id, :favorable_type], message: Proc.new { |error, attributes| favorable_unique_error_message }}
  
  validates :favorable_id, uniqueness: {scope: :user_id, message: '你已经收藏过该微博'}, if: Proc.new{ |f| f.favorable_type == 'Feed'}
                                                                                                          
  validates :favorable_id, uniqueness: {scope: :user_id, message: '你已经收藏过该主题'}, if: Proc.new{ |f| f.favorable_type == 'Basket'}

end
