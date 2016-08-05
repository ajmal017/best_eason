require 'digest'
module Authentication
  class BCrypt
    STRETCHES = 10

    def self.pepper
      'fb8ce002e417a6f65c11d1281227bd4de2b126b35d35ef1d68cd62f1777671883e9431eb35b20568dc808831b170c7f0a1d18ee925062d12e7a4f2be12a51ede'
    end

    def self.encrypt(plain)
      ::BCrypt::Password.create("#{plain}#{pepper}", :cost => STRETCHES)
    end

    def self.decrypt?(password, encrypted_password)
      return false if encrypted_password.blank?
      bcrypt   = ::BCrypt::Password.new(encrypted_password)
      password = ::BCrypt::Engine.hash_secret("#{password}#{pepper}", bcrypt.salt)
      secure_compare(password, encrypted_password)
    end

    def self.secure_compare(a, b)
      return false if a.blank? || b.blank? || a.bytesize != b.bytesize
      l = a.unpack "C#{a.bytesize}"

      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res == 0
    end
  end

  class Encryption
    ENC_SALT = '(JhFanDaoAisGod$'

    class << self
      # 使用md5算法把明文转为密文
      def md5(text)
        Digest::MD5.hexdigest(text) unless text.blank?
      end

      # 对明文做再次加密
      def encrypt(plain)
        Encryption.md5(ENC_SALT + plain.to_s)
      end
    end
  end
end
