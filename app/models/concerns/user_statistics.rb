module UserStatistics
  extend ActiveSupport::Concern

  USER_ACTIVE_DEED = [
    ["活跃用户", "or"],
    ["连续活跃用户", "and"]
  ]

  def sign_user_active(platform="app")
    $redis.setbit(self.class.user_active_key(platform), id, 1)
  end

  module ClassMethods

    include Extract

    def active_user_ids_by_date(from_date, to_date, action, platform="app")
      keys = from_date.upto(to_date).map{|date| user_active_key(platform, date) }
      descKey = "tmp:user_active:result:#{Time.now.to_f}"
      $redis.bitop(action, descKey, keys)
      binary_to_ids(descKey)
    ensure
      $redis.del(descKey)
    end

    def user_active_key(platform, date=Time.now)
      "active_users:#{platform}:#{date.strftime("%Y%m%d")}"
    end

  end
end
