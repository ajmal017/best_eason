module GenerateAbbrev
  extend ActiveSupport::Concern

  included do
    before_create :create_abbrev

    def create_abbrev
      if self.abbrev.blank?
        k = generate_abbrev_base true
        c = AbbrevCount.find_or_initialize_by(category: self.class.name, abbrev: k)
        # ret = k + (c.sequence_number.blank? ? '' : c.sequence_number.to_s) # 获得带序号的短链接
        c.increment(:sequence_number) # 更新序号
        c.save!
        self.abbrev = k
      end
    end

  end

  #默认字段name,如果使用其它字段请声明方法origin_abbrev
  def abbrev_cn_string
    return origin_abbrev.strip.truncate(14, omission: '') if self.respond_to?(:origin_abbrev, true)

    name.strip.truncate(14, omission: '')
  end

  # 短链接基础字符串
  def generate_abbrev_base polyphone = false
    cn_name ||= abbrev_cn_string rescue nil
    # 处理某些字的错误拼音
    [['猎', '列'], # xi
      ['术', '属'] # zhu
    ].each do |r|
      cn_name.gsub!(r[0], r[1])
    end
    ret = AbbrevCount.generate_abbrev_base cn_name

    if polyphone # 替换多音字部分
      [['银行', 'yinxing', 'yinhang'], ['畜牧', 'chumu', 'xumu'],
        ['给排水', 'geipaishui', 'jipaishui'], ['供给', 'gonggei', 'gongji'],
        ['给水', 'geishui', 'jishui'], ['会计', 'huiji', 'kuaiji'],
        ['角斗', 'jiaodou', 'juedou'], ['厦门', 'shamen', 'xiamen'],['校对', 'xiaodui', 'jiaodui'],
        ['分行', 'fenxing', 'fenhang'], ['支行', 'zhixing', 'zhihang']
      ].each do |r|
        ret.gsub!(r[1], r[2]) if cn_name =~ Regexp.new(r[0])
      end
    end

    ret
  end
end
