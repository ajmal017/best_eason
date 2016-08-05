module Admin::TopicsHelper
  def simple_percent_format(percent)
    return "--" if percent.blank?
    if percent >= 0
      "+#{percent.round(1)}%"
    else
      "#{percent.round(1)}%"
    end
  end
end
