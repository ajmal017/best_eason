class UserCertification < ActiveRecord::Base
  belongs_to :user

  validates :id_no, uniqueness: true, length: { is: 18 }, presence: true, id_no: true
  validates :real_name, realname: true

  MAX_TRY_COUNT = Rails.env.production? ? 5 : 1

  def third_party_certification
    P2pService.user_certification(user, id_number: id_no, name: real_name)
    return true
  rescue
    return false
  ensure
    # 记录认证次数
    UserCertification.add_certification_count(user.id)
  end

  def hide_id_no
    id_no.first(6) + "*"*8 + id_no.last(4)
  end

  class << self

    def count_key(user_id)
      "user_certification:#{user_id}:#{Date.today.strftime('%Y%m%d')}"
    end

    def certification_count(user_id)
      $redis.get(count_key(user_id)).to_i
    end

    def add_certification_count(user_id)
      key = count_key(user_id)
      if $redis.exists(key)
        $redis.incr(key).to_i
      else
        $redis.setex(key, 86400, 1)
        1
      end
    end

    def exceed_count?(user_id)
      # (Rails.env.production? || Rails.env.staging?) && certification_count(user_id) >= MAX_TRY_COUNT
      certification_count(user_id) >= MAX_TRY_COUNT
    end

  end
end
