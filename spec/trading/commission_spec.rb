require 'spec_helper'

describe 'Commission' do
  describe 'instance methods' do
    let(:com)  { Trading::Commission.new(commission_hash) }
    
    def commission_hash
      { commission: 22.03, currency: "HKD", exec_id: "0000f0e6.53f26ece.01.01", realized_pnl: "1.7976931348623157E308", yield: "1.7976931348623157E308", yield_redemption_date: 0 }
    end
    
    before :each do
      @user = create(:binding_user)
      create(:account_value, user_id: @user.id, key: "LastTotalCash", value: 1234324234, currency: "BASE")
      @basket = create(:basket_with_appl_and_yhoo)
      @order = build(:order, real_cost: 2, instance_id: @basket.id, basket_id: @basket.id, user_id: @user.id, order_details_attributes: order_details_attributes(@basket))
      @order.save(validate: false)
      create(:exec_detail, type: "ApiExec", side: "BOT", symbol: "AAPL", contract_id: "12150119", exec_id: "0000f0e6.53f26ece.01.01", price: 15.52, shares: 400, avg_price: "15.52", order_id: @order.id)
    end
    
    it 'returns api_exec' do
      expect(com.send(:api_order)).to be_kind_of(ApiExec)
    end
    
    it 'returns order_detail' do
      expect(com.send(:order_detail)).to be_kind_of(OrderDetail)
    end
    
    it 'creates one CommissionReport' do
      expect { com.create_commission }.to change(CommissionReport, :count).by(1)
    end
    
    it 'returns false' do
      expect(com.processed?).to eq false
    end
    
    describe 'compute' do
      it 'changes order_detail commission' do
        expect { com.compute }.to change { @order.order_details.first.reload.commission }.to(22.03)
      end
      
      it 'changes order commission' do
        expect { com.compute }.to change { @order.reload.commission }.to(22.03)
      end
      
      it 'changes api_exec status' do
        expect { com.compute }.to change { ApiExec.last.processed }.to(true)
      end
    end
  end
end
