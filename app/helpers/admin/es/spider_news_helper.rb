module Admin::ES::SpiderNewsHelper

  def highlighted(object, field)
    if h = object.try(:hit).try(:highlight).try(field).try(:first)
      raw(h)
    else
      raw(field.to_s.split('.').reduce(object) { |result,item| result.try(item) })
    end
  end
  
end
