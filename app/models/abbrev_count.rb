class AbbrevCount < ActiveRecord::Base

  def self.generate_abbrev_base(cn_string)
    ret = Pinyin.t(cn_string || '').gsub(/[^0-9a-zA-Z]|[0-9]+$/, '').downcase 
    ret.gsub!(/(^[0-9]+)|([0-9]+$)/, '') 
    ret = '' if ret.blank? 

    ret
  end

end
