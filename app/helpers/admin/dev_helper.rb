module Admin::DevHelper
  def code(key, language=:ruby)
    str = AdminTemplate::CODES[key]
    CodeRay.scan(str, language||:ruby).div(:css => :class)
  end

end
