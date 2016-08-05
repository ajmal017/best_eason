module Admin::ES::NewsHelper

  def highlighted(object, field)
    if h = object.try(:hit).try(:highlight).try(field).try(:first)
      h.html_safe
    else
      field.to_s.split('.').reduce(object) { |result,item| result.try(item) }
    end
  end
  
end
