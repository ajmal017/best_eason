# 加密工具集的统一出口
# 
# 方法命名规则:
#   加密方法: 对应实现类的
#   解密方法名为：  "decode_" + 对应的加密方法名
module Caishuo::Utils

  module Encryption

    class << self

      # Caishuo::Utils::Encryption.md5(datas)
      def md5(datas)
        Caishuo::Utils::Encryption::MD5.encode(datas)
      end

      # Caishuo::Utils::Encryption.pretty_id(obj_id)
      def pretty_id(obj_id)
        Caishuo::Utils::Encryption::PrettyId.encode(obj_id)
      end

      # Caishuo::Utils::Encryption.decode_pretty_id(obj_id)
      def decode_pretty_id(obj_id)
        Caishuo::Utils::Encryption::PrettyId.decode(obj_id)
      end

    end

  end

end

require "utils/encryption/md5"
require "utils/encryption/pretty_id"
require "utils/encryption/url_safe"