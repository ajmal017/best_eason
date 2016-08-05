class ActiveModel::Validations::IdNoValidator < ActiveModel::EachValidator
  # 身份证号验证
  WIGHTS=[7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
  TRANS = %w{1 0 X 9 8 7 6 5 4 3 2}

  def validate_each(record, attribute, value)
    value = value.to_s
    return record.errors.add(attribute, options[:message] || :format) if value.length != 18
    last = TRANS[value[0..-2].split('').each_with_index.inject(0){|sum, (val, idx)| sum += val.to_i*WIGHTS[idx]}.modulo(11)]
    record.errors.add(attribute, options[:message] || :format) unless last == value[-1]
  end
end