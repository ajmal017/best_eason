class ActiveModel::Validations::CustomLengthValidator < ActiveModel::EachValidator
  # 本处汉字占2个长度，其它字符占1个长度：
  #   如限定length为8，则“人民共和国”、“共和国333”等不合法
  #   参数：max: 最大长度, message: 错误提示文字
  #   参数：min: 最小长度, message: 错误提示文字

  def validate_each(record, attribute, value)
    real_length = value.to_s.strip.length
    length_except_han = value.to_s.strip.gsub(/\p{Han}+/, "").length
    custom_length = (real_length - length_except_han) * 2 + length_except_han
    if custom_length > options[:max].to_i
      record.errors.add(attribute, options[:message] || :custom_length_long)
    elsif custom_length < options[:min].to_i
      record.errors.add(attribute, options[:message] || :custom_length_short)
    end
  end
end
