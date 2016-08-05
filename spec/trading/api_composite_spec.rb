require 'spec_helper'

describe 'ApiComposite' do
  describe 'instance methods' do
    let(:api_composite)  { Trading::ApiComposite.new(exec_details_hash(@basket.try(:id), @order.try(:id))["exec"].select {|e| e["type"] == "API"}.inject([]) { |sum, detail| sum << detail }, "DU186929") }
    
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
    
    subject { api_composite.send(:log) }
    it 'create apis' do
      expect { subject }.to change(ApiExec, :count).by(2)
    end
    
    it 'returns valid apis' do
      expect(api_composite.send(:valid_apis).size).to eq 2
    end
    
    describe 'reconcile' do
      it 'invoked log' do
        api_composite.stub(:log).and_return(nil)
        api_composite.reconcile
        expect(api_composite).to have_received(:log)
      end
      
      subject { api_composite.reconcile }
      it 'changes status of order_details to filled' do
        expect { subject }.to change { @order.order_details.map(&:reload).map(&:status) }.from(["ready", "ready"]).to(["filled", "filled"])
      end
      
      it 'changes real_shares of order_details' do
        expect { subject }.to change { @order.order_details.map(&:reload).map(&:real_shares) }.from([nil, nil]).to([1000, 1000])
      end
      
      it 'changes real_cost of order_details' do
        expect { subject }.to change { @order.order_details.map(&:reload).map(&:real_cost) }.from([nil, nil]).to([15540, 15520])
      end
      
      it 'changes real_cost of order' do
        expect { subject }.to change { @order.reload.real_cost }.from(2).to(15540 + 15520 + 2)
      end
      
      it 'changes order_details_complete_count of order' do
        expect { subject }.to change { @order.reload.order_details_complete_count }.from(0).to(2)
      end
      
      it 'changes shares of positions' do
        api_composite.reconcile
        p1 = Position.find_by(instance_id: @basket.id, user_id: @user.id, base_stock_id: @order.order_details.first.stock.id)
        p2 = Position.find_by(instance_id: @basket.id, user_id: @user.id, base_stock_id: @order.order_details.last.stock.id)
        expect([p1.shares, p2.shares]).to eq [-1000, 1000]
      end
      
      it 'changes average_cost of BOT positions' do
        api_composite.reconcile
        p1 = Position.find_by(instance_id: @basket.id, user_id: @user.id, base_stock_id: @order.order_details.first.stock.id)
        p2 = Position.find_by(instance_id: @basket.id, user_id: @user.id, base_stock_id: @order.order_details.last.stock.id)
        expect([p1.average_cost, p2.average_cost]).to eq ([0, 15.52])
      end
      
      it 'changes pending_shares of SLD positions' do
        api_composite.reconcile
        p1 = Position.find_by(instance_id: @basket.id, user_id: @user.id, base_stock_id: @order.order_details.first.stock.id)
        p2 = Position.find_by(instance_id: @basket.id, user_id: @user.id, base_stock_id: @order.order_details.last.stock.id)
        expect([p1.pending_shares, p2.pending_shares]).to eq ([-1000, nil])
      end
    end
  end
end
