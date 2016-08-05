class ActiveModel::Validations::RealnameValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    value = value.to_s
    return record.errors.add(attribute, "真实姓名需要在2-15个字符之间") if value.length > 15 || value.length < 2
    match_result = /^[\u4E00-\u9FA5]{2,5}(?:·[\u4E00-\u9FA5]{2,5})*$/.match(value)
    record.errors.add(attribute, "真实姓名格式不合法") unless match_result.present?
  end
end
