require 'spec_helper'

describe 'CommissionComposite' do
  describe 'instance methods' do
    let(:com)  { Trading::CommissionComposite.new(commissions) }
    
    def commissions
      [
        { commission: 22.03, currency: "HKD", exec_id: "0000f0e6.53f26ece.01.01", realized_pnl: "1.7976931348623157E308", yield: "1.7976931348623157E308", yield_redemption_date: 0 },
        { commission: 22.05, currency: "HKD", exec_id: "0000f0e6.53f26ece.01.02", realized_pnl: "1.7976931348623157E308", yield: "1.7976931348623157E308", yield_redemption_date: 0 }
      ]
    end
    
    before :each do
      @user = create(:binding_user)
      create(:account_value, user_id: @user.id, key: "LastTotalCash", value: 1234324234, currency: "BASE")
      @basket = create(:basket_with_appl_and_yhoo)
      @order = build(:order, real_cost: 2, instance_id: @basket.id, basket_id: @basket.id, user_id: @user.id, order_details_attributes: order_details_attributes(@basket))
      @order.save(validate: false)
      create(:exec_detail, type: "ApiExec", side: "BOT", symbol: "AAPL", contract_id: "12150119", exec_id: "0000f0e6.53f26ece.01.01", price: 15.52, shares: 400, avg_price: "15.52", order_id: @order.id)
      create(:exec_detail, type: "ApiExec", side: "BOT", symbol: "AAPL", contract_id: "12150121", exec_id: "0000f0e6.53f26ece.01.02", price: 15.52, shares: 400, avg_price: "15.52", order_id: @order.id)
    end
    
    it 'create commissions' do
      expect { com.send(:log) }.to change(CommissionReport, :count).by(2)
    end
    
    describe 'compute' do
      it 'invokes log' do
        expect(com).to receive(:log)
        com.compute
      end
      
      it 'changes order commission' do
        expect { com.compute }.to change { @order.reload.commission }.to(22.03 + 22.05)
      end
    end
  end
end
