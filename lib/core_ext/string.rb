class String
 
  # 多音字银行会计分行支行
  def to_pinyin
    Pinyin.t(self, '').gsub('yinxing', 'yinhang').gsub('huiji', 'kuaiji')
          .gsub('fenxing', 'fenhang').gsub('zhixing', 'zhihang')
  end
  
  def to_number
    if self =~ /T/
      self.to_f * 1000000000000
    elsif self =~ /B/
      self.to_f * 1000000000
    elsif self =~ /M/
      self.to_f * 1000000
    else
      self.to_f
    end
  end
  
  def to_c_unit
    if self.to_number/1000000000000 >= 1
      num = self.to_number/1000000000000
      unit =  "万亿"
    elsif self.to_number/100000000 >= 1
      num = self.to_number/100000000
      unit = "亿"
    else
      num = self.to_number/10000
      unit = "万"
    end
    Caishuo::Utils::Helper.pretty_number(num, 2, false) + unit
  end

  # 以亿为单位，绝对保留2位小数
  def to_c_yi_unit(has_unit = false)
    num = self.to_number/100000000
    num_str = num.round(2).to_s(:delimited)
    formated_str = Caishuo::Utils::Helper.pretty_number(num_str, 2, false)
    has_unit ? formated_str + "亿" : formated_str
  end
  
  def to_h
    XmlSimple.xml_in(self, { 'KeyAttr' => 'name', 'KeepRoot' => true, 'ForceArray' => false })
  end
  
  # 去掉中文空格
  def full_strip
    self.strip.gsub(/(^[[:space:]]+)|[[:space:]]+$/, '')
  end

  # 替换全角到半角
  def full_width_tr
    self.full_strip.tr('ａ-ｚ', 'a-z').tr('Ａ-Ｚ', 'A-Z')
  end
  
  # 字符串转化为美国东部时间
  def to_estime
    self.in_time_zone('Eastern Time (US & Canada)')
  end

end

class Array
  
  # 数组直接转成Hash,Ruby2.1已经定义to_h方法
  def to_h
    Hash[self]
  end unless method_defined?(:to_h)

end
