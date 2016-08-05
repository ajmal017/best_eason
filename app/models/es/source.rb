class ES::Source < ActiveRecord::Base
  validates :code,  presence: true, uniqueness: true
  validates :name, presence: true
  validates :url,  presence: true, uniqueness: true

end
