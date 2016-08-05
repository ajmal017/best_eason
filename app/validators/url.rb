class ActiveModel::Validations::UrlValidator < ActiveModel::EachValidator
  
  def validate_each(record, attribute, value)
    begin
      uri = URI.parse(value)
      result = uri.kind_of?(URI::HTTP)
    rescue URI::InvalidURIError
      result = false
    end
    unless result
      record.errors.add(attribute, :illegal)
    end
  end
end
