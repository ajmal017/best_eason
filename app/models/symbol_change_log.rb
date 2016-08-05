class SymbolChangeLog < ActiveRecord::Base
  
  def self.log_info(base_id, field, message)
    self.create(base_stock_id: base_id, field: field, log: message, log_type: "INFO")
  end
  
  def self.log_error(base_id, field, message)
    self.create(base_stock_id: base_id, field: field, log: message, log_type: "ERROR")
  end

  after_create :send_notification, if: "self.log_type == 'ERROR'"
  def send_notification
    Caishuo::Utils::Email.deliver(Setting.notifiers.email, self.base_stock_id.try(:to_s), self.log)
  rescue
    true
  end
end
