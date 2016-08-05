require 'spec_helper'

describe 'TwsComposite' do
  describe 'instance methods' do
    let(:tws_composite)  { Trading::TwsComposite.new(exec_details_hash(@basket.try(:id), @order.try(:id))["exec"].select {|e| e["type"] == "TWS"}.inject([]) { |sum, detail| sum << detail }, "DU186929") }
    
    before :each do
      @user = create(:binding_user)
      allow_any_instance_of(UserBinding).to receive(:request_account_value).and_return(nil)
      create(:user_binding, user_id: @user.id, broker_user_id: "DU186929")
      create(:account_value, user_id: @user.id, key: "LastTotalCash", value: 1234324234, currency: "BASE")
      @basket = create(:basket_with_appl_and_yhoo)
      @order = build(:order, real_cost: 2, instance_id: @basket.id, basket_id: @basket.id, user_id: @user.id, order_details_attributes: order_details_attributes(@basket))
      @order.save(validate: false)
      allow_any_instance_of(Order).to receive(:notify_complete).and_return(nil)
    end
    
    subject { tws_composite.send(:log) }
    it 'create 2 tws' do
      expect { subject }.to change(TwsExec, :count).by(2)
    end
    
    it 'promote_reconcile_level' do
      expect { tws_composite.promote_reconcile_level }.to change { @user.user_binding.count }.by(1)
    end
    
    it 'initialize_reconcile_level' do
      expect { tws_composite.initialize_reconcile_level }.to change { @user.user_binding.count }.to(0)
    end
    
    it 'returns unprocessed_tws_details' do
      allow_any_instance_of(Trading::TwsDetail).to receive(:processed?).and_return(false)
      expect(tws_composite.send(:unprocessed_tws_details).count).to eq 2
    end
    
    it 'returns a hash' do
      allow_any_instance_of(Trading::TwsDetail).to receive(:processed?).and_return(false)
      expect(tws_composite.send(:tws_group_by_contract_id)).to be_kind_of(Hash)
    end
    
    it 'returns a hash with value' do
      allow_any_instance_of(Trading::TwsDetail).to receive(:processed?).and_return(false)
      expect(tws_composite.send(:symbol_with_count)).to include("12150119" => 200)
    end
    
    it 'returns a stock by id' do
      expect(tws_composite.send(:stock_by, "12150119")).to be_kind_of(BaseStock)
    end
    
    it 'sets user_binding unavailable' do
      tws_composite.send(:set_user_status, false)
      expect(@user.user_binding.available).to eq false
    end
    
    it 'sets user_binding available' do
      expect { tws_composite.send(:set_user_status, true) }.to change { @user.user_binding.available }.to(true)
    end
    
    it 'creates one reconcile_request' do
      expect { tws_composite.send(:reconcile_request) }.to change(ReconcileRequestList, :count).by(1)
    end
    
    it 'changes reconcile_request symbol' do
      expect { tws_composite.send(:send_reconcile_request, "AAPL,YHOO") }.to change { ReconcileRequestList.last.try(:symbol) }.to("AAPL,YHOO")
    end
    
    it 'destroy one reconcile_request' do
      tws_composite.send(:destroy_reconcile_request)
      expect(ReconcileRequestList.count).to eq 0
    end
    
    it 'reconciled one symbol' do
      expect(tws_composite).to receive(:initialize_reconcile_level)
      expect(tws_composite).to receive(:set_user_status).with(true)
      expect(tws_composite).to receive(:destroy_reconcile_request)
      tws_composite.send(:reconciled!)
    end
    
    it 'unreconciled! some symbols' do
      expect(tws_composite).to receive(:promote_reconcile_level)
      expect(tws_composite).to receive(:set_user_status).with(false)
      expect(tws_composite).to receive(:send_reconcile_request).with("AAPL,YHOO")
      tws_composite.send(:unreconciled!, "AAPL,YHOO")
    end
    
    describe 'unreconciled_symbol' do
      context 'unreconciled' do
        it 'returns one unreconciled symbol' do
          stock = tws_composite.send(:stock_by, "12150119")
          tws_shares = 200
          expect(tws_composite.send(:unreconciled_symbol, stock, tws_shares)).to eq "AAPL"
        end
      end
      context 'reconciled' do
        before :each do
          create(:portfolio, position: 400, user_id: @user.id, base_stock_id: @order.order_details.first.stock.id)
          create(:position, shares: 200, user_id: @user.id, base_stock_id: @order.order_details.first.stock.id)
        end
        
        it 'returns nil' do
          stock = tws_composite.send(:stock_by, "12150119")
          tws_shares = 200
          expect(tws_composite.send(:unreconciled_symbol, stock, tws_shares)).to eq nil
        end  
      end
      
    end
    
    describe 'tws_unreconciled_symbols' do
      context 'unreconciled' do
        it 'returns unreconciled symbols' do
          allow_any_instance_of(Trading::TwsDetail).to receive(:processed?).and_return(false)
          expect(tws_composite.send(:tws_unreconciled_symbols)).to eq ["AAPL"]
        end
      end
      
      context 'reconciled' do
        before :each do
          create(:portfolio, position: 400, user_id: @user.id, base_stock_id: @order.order_details.first.stock.id)
          create(:position, shares: 200, user_id: @user.id, base_stock_id: @order.order_details.first.stock.id)
        end
        
        it 'returns []' do
          allow_any_instance_of(Trading::TwsDetail).to receive(:processed?).and_return(false)
          expect(tws_composite.send(:tws_unreconciled_symbols)).to eq []
        end
      end
    end
    
    describe 'user_unreconciled_symbols' do
      before :each do
        create(:portfolio, position: 400, user_id: @user.id, base_stock_id: @order.order_details.first.stock.id)
        create(:position, shares: 200, user_id: @user.id, base_stock_id: @order.order_details.first.stock.id)
        create(:exec_detail, type: "TwsExec", side: "BOT", symbol: "AAPL", contract_id: "12150119", exec_id: "0000f0e6.53f26ed2.01.01", price: 15.52, shares: 400, avg_price: "15.52")
        create(:exec_detail, type: "TwsExec", side: "SLD", symbol: "AAPL", contract_id: "12150119", exec_id: "0000f0e6.53f26ed3.01.01", price: 15.52, shares: 200, avg_price: "15.52")
      end
      context 'unreconciled' do
        it 'returns unreconciled symbols' do
          expect(tws_composite.send(:user_unreconciled_symbols)).to eq ["AAPL"]
        end
      end
      
      context 'reconciled' do
        before :each do
          create(:position, shares: 200, user_id: @user.id, base_stock_id: @order.order_details.first.stock.id)
        end
        it 'returns []' do
          expect(tws_composite.send(:user_unreconciled_symbols)).to eq []
        end
      end
    end
    
    describe 'reconcile_tws_details' do
      context 'tws unreconciled' do
        before :each do
          allow_any_instance_of(Trading::TwsDetail).to receive(:processed?).and_return(false)
        end
        it 'does not invoke user_unreconciled_symbols' do
          expect(tws_composite).to_not receive(:user_unreconciled_symbols)
          tws_composite.send(:reconcile_tws_details)
        end
        it 'invokes unreconciled!' do
          expect(tws_composite).to receive(:unreconciled!).with("AAPL")
          tws_composite.send(:reconcile_tws_details)
        end
      end
      
      context 'tws reconciled' do
        describe 'user reconciled' do
          before :each do
            create(:portfolio, position: 400, user_id: @user.id, base_stock_id: @order.order_details.first.stock.id)
            create(:position, shares: 200, user_id: @user.id, base_stock_id: @order.order_details.first.stock.id)
            create(:exec_detail, type: "TwsExec", side: "BOT", symbol: "AAPL", contract_id: "12150119", exec_id: "0000f0e6.53f26ed2.01.01", price: 15.52, shares: 400, avg_price: "15.52")
            create(:exec_detail, type: "TwsExec", side: "SLD", symbol: "AAPL", contract_id: "12150119", exec_id: "0000f0e6.53f26ed3.01.01", price: 15.52, shares: 200, avg_price: "15.52")
          end
        
          it 'invokes user_unreconciled_symbols' do
            expect(tws_composite).to receive(:user_unreconciled_symbols)
            tws_composite.send(:reconcile_tws_details)
          end
        
          it 'changes tws_exec status to processed' do
            expect { tws_composite.send(:reconcile_tws_details) }.to change { [TwsExec.first.processed, TwsExec.last.processed] }.to([true, true])
          end
        
          it 'create one others position' do
            expect { tws_composite.send(:reconcile_tws_details) }.to change { Position.where(instance_id: "others").count }.by(1)
          end
        
          it 'create one others position with right shares' do
            expect { tws_composite.send(:reconcile_tws_details) }.to change { Position.find_by(instance_id: "others").try(:shares) }.to(200)
          end
        
          it 'create one others position with right average_cost' do
            expect { tws_composite.send(:reconcile_tws_details) }.to change { Position.find_by(instance_id: "others").try(:average_cost) }.to(15.52)
          end
        end
        
      end
    end
    
    describe 'reconcile' do
      subject { tws_composite.reconcile }
      it 'create two tws_exec' do
        expect { subject }.to change(TwsExec, :count).by(2)
      end
      
      it 'invokes reconcile_tws_details' do
        expect(tws_composite).to receive(:reconcile_tws_details)
        tws_composite.reconcile
      end
    end
  end
end
