module Xmlable
  extend ActiveSupport::Concern

  included do

    # def expiry
    #   (created_at.getgm + ::Setting.order_validity_period.to_i.minutes).to_s
    # end

    def advAccount
      trading_account.broker.master_account
    end

    def subAccount
      trading_account.broker_no
    end

  end
end
