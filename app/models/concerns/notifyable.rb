module Notifyable 
  extend ActiveSupport::Concern
  included do
    after_create :send_notification
    before_destroy :delete_notification
  end

end
