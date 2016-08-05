require 'tws_detail'
module Trading

  class TwsComposite
    extend Forwardable

    def_delegators :@account, :premote_reconcile_level, :initialize_reconcile_level

    def initialize(tws_details = [], account)
      @account = TradingAccount.find_by!(broker_no: account)
      @twses = tws_details.map { |tws| TwsDetail.new(tws, @account) rescue nil }.compact
    end

    def reconcile
      log
      reconcile_tws_details
    end

    private
    def log
      @twses.map(&:create_tws_order)
    end

    def reconcile_tws_details
      symbols = tws_unreconciled_symbols
      symbols = user_unreconciled_symbols if symbols.blank?
      symbols.blank? ? reconciled! : unreconciled!(symbols.join(","))
    end

    def allocate
      @account.allocate
    end

    def corporate
      destroy_zero_positions

      b_ps = @account.corporated_from_position
      a_ps = @account.corporated_to_position

      if a_ps.present? && b_ps.present?
        b_ps.each do |b_p|
          a_ps.each do |a_p|
            if ca = (StockChange.find_by(from_id: b_p.base_stock_id, to_id: a_p.base_stock_id) || CaSplit.can_split?(b_p.base_stock))
              factor = (ca.before_split/ca.after_split).round(15)
              if shares_at_ratio?(factor, b_p.shares.abs, a_p.shares.abs)
                split(factor, b_p.base_stock_id, a_p.base_stock_id) 
                StockChange.find_or_initialize_by(from_id: b_p.base_stock_id, to_id: a_p.base_stock_id).update(from_symbol: b_p.base_stock.symbol, to_symbol: a_p.base_stock.symbol, date: Time.now.to_date, factor: ca.factor)
              end
            elsif StockChange.find_by(from_id: a_p.base_stock_id, to_id: b_p.base_stock_id) || CaSplit.can_split?(a_p.base_stock)
              split(1, b_p.base_stock_id, a_p.base_stock_id) if come_back?(b_p.shares.abs, a_p.shares.abs)
            end
          end
        end
      end
    end

    #def corporate
      #destroy_zero_positions

      #b_p = @user.corporated_from_position
      #a_p = @user.corporated_to_position
      #if a_p.present? && b_p.present?
        #if ca = (StockChange.find_by(from_id: b_p.base_stock_id, to_id: a_p.base_stock_id) || CaSplit.can_split?(b_p.base_stock))
          #factor = (ca.before_split/ca.after_split).round(15)
          #if shares_at_ratio?(factor, b_p.shares.abs, a_p.shares.abs)
            #split(factor, b_p.base_stock_id, a_p.base_stock_id) 
            #StockChange.find_or_initialize_by(from_id: b_p.base_stock_id, to_id: a_p.base_stock_id).update(from_symbol: b_p.base_stock.symbol, to_symbol: a_p.base_stock.symbol, date: Time.now.to_date, factor: ca.factor)
          #end
        #elsif StockChange.find_by(from_id: a_p.base_stock_id, to_id: b_p.base_stock_id) || CaSplit.can_split?(a_p.base_stock)
          #split(1, b_p.base_stock_id, a_p.base_stock_id) if come_back?(b_p.shares.abs, a_p.shares.abs)
        #end
      #end
    #end

    def destroy_zero_positions
      Position.allocated.account_with(@account.id).where("shares is NULL or shares = ?", 0).delete_all
    end

    def split(factor, before_id, after_id)
      Position.account_with(@account.id).stock_with(before_id).allocated.each do |p|
        p.update(base_stock_id: after_id, shares: p.shares.to_i * factor, average_cost: p.average_cost/factor)
      end
      destroy_unallocate_positions([before_id, after_id])
    end

    def destroy_unallocate_positions(ids)
      Position.unallocated.account_with(@account.id).stock_with(ids).delete_all
    end

    def come_back?(before_shares, after_shares)
      shares_at_ratio?(1, before_shares, after_shares)
    end

    def shares_at_ratio?(factor, before_shares, after_shares)
      before_shares * factor == after_shares
    end

    def user_unreconciled_symbols
      @account.unreconciled_symbols
    end

    def tws_unreconciled_symbols
      symbols = []
      symbol_with_count.each do |(ib_id, ib_symbol), tws_shares|
        symbols << unreconciled_symbol(stock_by(ib_id, ib_symbol), tws_shares) if stock_by(ib_id, ib_symbol)
      end
      symbols.compact
    end

    def unreconciled_symbol(stock, tws_shares)
      allocated_shares = Position.account_with(@account.id).stock_with(stock.id).allocated.sum(:shares)
      portfolio = Portfolio.account_with(@account.id).stock_with(stock.id).sum(:position)
      $pms_logger.info("ExecDetails Tws: #{stock.ib_symbol},#{allocated_shares},#{tws_shares},#{portfolio}") if Setting.pms_logger
      if tws_shares + allocated_shares != portfolio
          symbol = stock.split(@account)
      else
        $pms_logger.info("ExecDetails Tws: 能够调平") if Setting.pms_logger
        stock.reconcile!(@account)
        symbol = nil
      end
      symbol
    end

    def symbol_with_count
      Hash[ tws_group_by_contract_id_symbol.map { |ib_id, details| [ib_id, details.inject(0) {|sum, detail| sum = (detail.side == "BOT" ? sum + detail.shares.to_d : sum - detail.shares.to_d) }] } ]
    end

    def tws_group_by_contract_id_symbol
      unprocessed_tws_details.group_by { |detail| [detail.contract_id, detail.symbol] }
    end

    def unprocessed_tws_details
      @twses.reject { |detail| detail.processed? }
    end

    def stock_by(ib_id, ib_symbol)
      BaseStock.find_by(ib_id: ib_id) || BaseStock.find_by(ib_symbol: ib_symbol)
    end

    def send_reconcile_request(reconcile_symbol)
      reconcile_request.update_attributes(broker_user_id: @account.broker_no, symbol: reconcile_symbol, updated_by: "updatePortfolio")
    end

    def reconcile_request
      @reconcile_request ||= ::ReconcileRequestCts.find_or_create_by(trading_account_id: @account.id)
    end

    def destroy_reconcile_request
      reconcile_request.destroy!
    end

    def reconciled!
      $pms_logger.info("ExecDetails Tws: 全部调平") if Setting.pms_logger
      initialize_reconcile_level
      destroy_reconcile_request
      destroy_all_unallocate_positions
    end

    def destroy_all_unallocate_positions
      Position.unallocated.account_with(@account.id).delete_all
    end

    def unreconciled!(symbols)
      $pms_logger.info("ExecDetails Tws: unreconciled_symbols=#{symbols}") if Setting.pms_logger
      allocate
      corporate
      premote_reconcile_level
      send_reconcile_request(symbols)
    end
  end

end
