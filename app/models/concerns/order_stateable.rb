module OrderStateable
  extend ActiveSupport::Concern

  def self.included(klass)
    klass.send(:include, InstanceMethods)
    klass.class_eval do
      include AASM
      aasm :skip_validation_on_save => true, :column => :status do
        state :unconfirmed, :initial => true
        state :confirmed
        state :cancelling
        state :partial_completed
        state :completed
        state :cancelled
        state :expired
        state :error

        event :confirm, :after => [ :initialize_pending_shares ] do
          transitions :from => :unconfirmed, :to => :confirmed
        end

        event :complete do
          transitions :from => [:unconfirmed, :confirmed, :cancelling], :to => :completed
        end
        
        event :partial_complete do
          transitions :from => [:unconfirmed, :confirmed, :cancelling], :to => :partial_completed
        end

        event :cancel do
          transitions :from => [:unconfirmed, :confirmed], :to => :cancelling
        end
        
        event :real_cancel do
          transitions :from => [:unconfirmed, :confirmed, :cancelling], :to => :cancelled
        end
    
        event :expire do
          transitions :from => [:unconfirmed, :confirmed, :cancelling], :to => :expired
        end
    
        event :to_error, :after => [:notify_admins] do
          transitions :from => [:unconfirmed, :confirmed, :cancelling], :to => :error
        end

        event :admin_cancell, :after => [:notify_admins, :cancell_order_details] do
          transitions :from => [:unconfirmed, :confirmed, :cancelling], :to => :cancelled
        end
      end
    end
  end

  module InstanceMethods

    def notify_admins
    
    end

    def cancell_order_details
      self.order_details.map(&:admin_cancell!)
    end
  
    def send_cancel_to_remote
      if market_cn?
        RestClient.trading.order.cancel(id)
      else
        OrderStatusPublisher.publish({ "advAccount" => trading_account.master_account, "basketId" => instance_order_id }.to_xml(root: 'cancel')) 
      end
    end
  
    def initialize_pending_shares
      if type == "OrderSell"
        order_details.each do |od|
          pos = Position.find_or_create_by(instance_id: instance_id, base_stock_id: od.base_stock_id, trading_account_id: od.trading_account_id)
          pos.update_attributes_with_lock(pending_shares: od.est_shares.to_i + pos.pending_shares.to_i)
        end
      end
    end

    def cancel_by_user
      self.cancel!
      send_cancel_to_remote
    end

    def confirm_by_user
      self.confirm!
      send_order_to_remote
    end

    def send_order_to_remote
      if market_cn?
        RestClient.trading.order.create(id)
      else
        OrderStatusPublisher.publish(self.to_xml_msg)
      end
    end
  
    def error_order_details
      order_details.map(&:to_error!)
    end
  
    def expire_order_details
      order_details.map(&:expire!)
    end

  end #InstanceMethods
end
