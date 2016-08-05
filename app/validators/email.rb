class ActiveModel::Validations::EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
      record.errors.add(attribute, :invalid, options.merge(:value => value))
    end
  end
end
