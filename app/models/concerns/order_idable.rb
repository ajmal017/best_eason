# 为Model添加生成伪ID的功能
# 
# Demo:
#   class User
#     include PrettyIdable
#   end
# 
#   pretty_id = User.first.pretty_id
#   user = User.find_by_pretty_id(pretty_id)
module OrderIdable
  extend ActiveSupport::Concern

  SN_SEEDS="KL12345STUVWXY89ABCDE67MNPQRFGHJ"

  included do
    attr_accessor :domain

    before_create :set_source
    after_create :set_sn
  end

  # 生成13位订单号
  # Demo: C814121000120
  # {source_code}{user_seed}{yymmdd}{id后5位}
  def sn
    return if id.blank?
    "#{source[0].upcase}#{SN_SEEDS[user_id % SN_SEEDS.size]}#{created_at.strftime("%y%m%d")}#{"%0.5d" % (id%10**5)}"
  end

  def set_sn
    self.update(sn: self.sn)
  end

  def set_source
    self.source ||= (/qianshi\.com\.hk$/.match(self.domain.to_s) ? "qianshi" : "caishuo")
  end
end