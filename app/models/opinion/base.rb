class Opinion::Base < ActiveRecord::Base
  self.table_name = :opinions

  OPINIONS = {"up" => 1, "down" => 2}

  validates :user_id, presence: true

  belongs_to :user
  belongs_to :opinionable, polymorphic: true

  scope :bullished, -> {where(:opinion => OPINIONS["up"])}
  scope :bearished, -> {where(:opinion => OPINIONS["down"])}
  scope :in_one_month, -> {where("post_time >= ?", 1.month.ago)}

end