module OrderManageable
  extend ActiveSupport::Concern

  def self.included(klass)
    klass.send(:include, InstanceMethods)
    klass.class_eval do
      delegate :realtime_price, :limit_price, :market?, to: :order_detail
      scope :in_progress, -> { where(status: ["confirmed", "cancelling"]) }
      scope :finished, -> { where(status: ["completed", "cancelled", "expired", "error", "partial_completed"]).order("created_at desc") }

      scope :filled, -> { where(status: ["completed", "partial_completed"]).order("created_at desc") }
      scope :basket_invest, -> { where.not(basket_id: nil) }
      scope :stock_invest, -> { where(basket_id: nil) }
    end
  end

  module InstanceMethods

    def basket?
      basket_id.present?
    end
  
    def total_shares
      order_details.map(&:est_shares).map(&:to_i).sum
    end
  
    def completed_shares
      order_details.map(&:real_shares).map(&:to_i).sum
    end
  
    def percent_complete
      (completed_shares/total_shares.to_f).round(2)
    end
    
    def order_detail
      order_details.first
    end
    
    def no_shares?
      self.order_details.all? { |od| od.real_shares.to_i == 0 }
    end
  
    def all_complete?
      self.order_details.all? { |od| od.real_shares.to_i >= od.est_shares }
    end
  
    def has_expired_order_detail?
      self.order_details.any? { |od| od.trade_time > od.order.expiry }
    end
  
    def has_error?
      self.order_details.any? { |od| od.status == "error" || od.status == "inactive" }
    end

    # A股市场价不能取消
    def can_cancel?
      may_cancel? && !(market_cn? && market?)
    end
  
    def all_cancelled?
      self.order_details.all? { |od| od.status == "cancelled" }
    end
    
    def has_cancelled?
      self.order_details.any? { |od| ["cancelled", "api_cancelled"].include?(od.status) }
    end
  
    def finish!
      case
      when all_complete?
        self.complete!
      when no_shares?
        if has_cancelled?
          self.real_cancel!
        elsif has_error?
          self.to_error!
        elsif has_expired_order_detail?
          self.expire!
        end
      else
        self.partial_complete!
      end
    end

  end #InstanceMethods
end
