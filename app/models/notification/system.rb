class Notification::System < Notification::Base
  include Countable
  include PushNotification

  attr_accessor :basket_audit_result, :unpass_reason

  def url
    case mentionable_type
    when "Basket"
      "/baskets/#{mentionable_id}"
    else
      "#"
    end
  end

  private
  def gen_title
    self.title =
      case basket_audit_result
      when 'pass'
        "组合创建成功"
      when 'not_pass'
        "组合创建失败"
      end
  end

  def gen_content
    self.content =
      case basket_audit_result
      when 'pass'
        basket_audit_pass_template
      when 'not_pass'
        basket_audit_not_pass_template
      end
  end

  def basket_audit_pass_template
    #content = <<-HTML
      #尊敬的主题投资作者：<br/>
      #你的主题投资 <span><a href="/baskets/#{self.mentionable.id}" target="_blank">#{self.mentionable.title}</a></span> ,已经通过审核。<br/>
      #财说
    #HTML
    "\"#{self.mentionable.title}\"已经通过审核"
  end

  def basket_audit_not_pass_template
    #content = <<-HTML
      #尊敬的主题投资作者：<br>
      #由于以下原因,你的主题投资 <span>#{self.mentionable.title}</span> 未通过审核,请适当调整后,再次申请。<br>
      #<span class="reasons">#{self.unpass_reason}<br>
        #<a href="/baskets/#{self.mentionable.id}/add" target="_blank">点击调整该主题。</a>
      #</span>
      #<br>
      #财说
    #HTML
    <<-HTML
      "#{self.mentionable.title}"未通过审核, <br>
      原因: #{self.unpass_reason}
    HTML
  end
end
