require "authentication/encryption"
require "authentication/base"


# In your ApplicationController
# include Authentication::Base 
# before_action :current_user, :access_denied
#
# In Model User
# has_secure_password

# Demo:
# def self.check_login?(email_or_mobile, password)
#   if email_or_mobile =~ /^\d{11}$/
#     User.find_by(mobile: email_or_mobile).try(:authenticate, password)
#   else
#     User.find_by(email: email_or_mobile).try(:authenticate, password)
#   end
# end
module Authentication

	UserBlocked = Class.new StandardError
	
end
