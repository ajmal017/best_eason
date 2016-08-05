class ActiveModel::Validations::SensitiveValidator < ActiveModel::EachValidator
  # 敏感词检测
  # 参数：show_words: true, false

  def validate_each(record, attribute, value)
    if value.present? && record.send("#{attribute}_changed?")
      words = Caishuo::Utils::TextFilter.check(value.gsub(" ", ""))
      if words.present?
        if options[:show_words]
          msg = "包含敏感词：#{words.first(3).join("，")}"
        else
          msg = options[:message] || "包含敏感词"
        end
        record.errors.add(attribute, msg)
      end
    end
  end
end