module Caishuo::Utils

  class Email
    
    def self.defaults
      Mail.defaults do
        delivery_method :smtp, address: "smtp.exmail.qq.com",
                              port: 25,
                              authentication: 'login', 
                              user_name: "system01@caishuo.com", 
                              password: "caishuo123"
      end
    end
    
    def self.deliver(to_user = nil, text = nil,  sub = nil, html = nil, from_name=nil)
      mail = Mail.new do
        to      to_user
        from    from_name || '财说-系统01 <system01@caishuo.com>'
        subject sub || 'Message from caishuo'

        text_part do
          body text
        end if text.present?

        html_part do
          content_type 'text/html; charset=UTF-8'
          body html
        end if html.present?
      end
      
      mail.deliver
    end

  end

end