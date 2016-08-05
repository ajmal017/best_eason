class Sms

  def self.official?
    Rails.env.production?
  end

  ALLOW_WRONG_COUNT = official? ? 10 : 100
  EXPIRED_TIME = 1800
  CD_TIME = 60

  class << self

    # 发送短信,并存入redis
    # return true/false
    def send(mobile)

      return false unless cd_time(mobile).zero?

      code = generage_code

      if send_sms(mobile, verify_code_content(code))
        set_sms_code_key(mobile, code)
        true
      else
        false
      end

    end

    def verify_code_content(code)
      "您的手机验证码为 #{code}"
    end

    # 剩余冷却时间
    def cd_time(mobile)
      return 0 if $redis.ttl(sms_key(mobile)) <= 0
      ttl_time = EXPIRED_TIME - $redis.ttl(sms_key(mobile))
      ttl_time < CD_TIME ? CD_TIME - ttl_time : 0
    end

    # 生成验证码
    def generage_code
      if official?
        rand(9999).to_s.rjust(4, '0')
      else
        "1234"
      end
    end

    # 验证短信
    # 验证成功或者失败超过一定次数后删除验证码记录
    # return true/false
    def verifty(mobile, code)
      result = code == $redis.get(sms_key(mobile))
    ensure
      del_sms_code_key(mobile) if result || (incr_sms_code(mobile) >= ALLOW_WRONG_COUNT)
    end

    def error_info(mobile)
      if $redis.exists(sms_key(mobile))
        "验证码不正确，还剩#{ALLOW_WRONG_COUNT - get_sms_code_count(mobile)}次机会"
      else
        "请发送验证码"
      end
    end

    # 对登录用户请求绑定手机号时发送验证码进行频率限制
    def bind_mobile_count(current_user)
      if $redis.exists("sms:bind_mobile:user:#{current_user.id}")
        $redis.incr("sms:bind_mobile:user:#{current_user.id}").to_i
      else
        $redis.setex("sms:bind_mobile:user:#{current_user.id}", 600, 1)
        1
      end
    end

    def send_sms(mobile, content)
      if official?
        RestClient.api.tool.sms(mobile, content)
      else
        true
      end
    end

    private
    def sms_key(mobile)
      "sms-code-#{mobile}"
    end

    def sms_count_key(mobile)
      "sms-code-count-#{mobile}"
    end

    def set_sms_code_key(mobile, code)
      $redis.setex(sms_key(mobile), EXPIRED_TIME, code)
      $redis.setex(sms_count_key(mobile), EXPIRED_TIME, 0)
    end

    def del_sms_code_key(mobile)
      $redis.del(sms_key(mobile))
      $redis.del(sms_count_key(mobile))
    end

    def incr_sms_code(mobile)
      if $redis.exists(sms_count_key(mobile))
        $redis.incr(sms_count_key(mobile)).to_i
      else
        0
      end
    end

    def get_sms_code_count(mobile)
      $redis.get(sms_count_key(mobile)).to_i
    end

  end
end
