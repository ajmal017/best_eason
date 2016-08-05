# 报名参加以后的实盘大赛记录表
class PreContestant < ActiveRecord::Base
  validates :user_id, uniqueness: {scope: [:contest_id]}

  belongs_to :user
  belongs_to :contest
end