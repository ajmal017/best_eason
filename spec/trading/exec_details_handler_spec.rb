require 'spec_helper'

describe 'ExecDetailsHandler' do
  describe 'instance methods' do
    let(:exec)  { Trading::ExecDetailsHandler.new(new_exec_details_hash(@basket.id, @order.id)) }
    
    before :each do
      @user = create(:binding_user)
      allow_any_instance_of(UserBinding).to receive(:request_account_value).and_return(nil)
      create(:user_binding, user_id: @user.id, broker_user_id: "DU186929")
      create(:account_value, user_id: @user.id, key: "LastTotalCash", value: 1234324234, currency: "BASE")
      @basket = create(:basket_with_appl_and_yhoo)
      @order = build(:order, real_cost: 2, instance_id: @basket.id, basket_id: @basket.id, user_id: @user.id, order_details_attributes: order_details_attributes(@basket))
      @order.save(validate: false)
      allow_any_instance_of(Order).to receive(:notify_complete).and_return(nil)
      create(:portfolio, position: 1200, user_id: @user.id, base_stock_id: @order.order_details.first.stock.id)
    end
    
    it 'returns account' do
      expect(exec.send(:account)).to eq "DU186929"
    end
    
    describe 'array_api_details' do
      it 'returns an Array' do
        expect(exec.send(:array_api_details)).to be_kind_of(Array)
      end
      
      it 'has all hash elements' do
        expect(exec.send(:array_api_details)).to have_all_hash_elements
      end
    end
    
    describe 'array_tws_details' do
      it 'returns an Array' do
        expect(exec.send(:array_tws_details)).to be_kind_of(Array)
      end
      
      it 'has all hash elements' do
        expect(exec.send(:array_tws_details)).to have_all_hash_elements
      end
    end
    
    describe 'details' do
      it 'returns an Hash' do
        expect(exec.send(:details)).to be_kind_of(Hash)
      end
      
      it 'has key api' do
        expect(exec.send(:details)).to have_key(:api)
      end
      
      it 'has key tws' do
        expect(exec.send(:details)).to have_key(:tws)
      end
    end
    
    describe 'commissions' do
      it 'returns an Array' do
        expect(exec.send(:commissions)).to be_kind_of(Array)
      end
    end
    
    describe 'perform' do
      it 'changes order status' do
        expect { exec.perform }.to change { @order.reload.status }.to("completed")
      end
      
      it 'changes order real_cost' do
        expect { exec.perform }.to change { @order.reload.real_cost }.to(15540 + 15520 + 2)
      end
      
      it 'changes order order_details_complete_count' do
        expect { exec.perform }.to change { @order.reload.order_details_complete_count }.to(2)
      end
      
      it 'changes order commission' do
        expect { exec.perform }.to change { @order.reload.commission }.to(22.03 + 22.05)
      end
      
      it 'changes order_detail status' do
        expect { exec.perform }.to change { [@order.order_details.first.reload.status, @order.order_details.last.reload.status] }.to(["filled", "filled"])
      end
      
      it 'changes order_detail real_shares' do
        expect { exec.perform }.to change { [@order.order_details.first.reload.real_shares, @order.order_details.last.reload.real_shares] }.to([1000, 1000])
      end
      
      it 'changes order_detail real_cost' do
        expect { exec.perform }.to change { [@order.order_details.first.reload.real_cost, @order.order_details.last.reload.real_cost] }.to([15540, 15520])
      end
      
      it 'changes order_detail commission' do
        expect { exec.perform }.to change { [@order.order_details.first.reload.commission, @order.order_details.last.reload.commission] }.to([22.03, 22.05])
      end
      
      it 'creates positions' do
        expect { exec.perform }.to change { Position.where.not(instance_id: "others").count }.by(2)
      end
      
      it 'create one others position' do
        expect { exec.perform }.to change { Position.where(instance_id: "others").count }.by(1)
      end
      
      it 'create one others position with right shares' do
        expect { exec.perform }.to change { Position.find_by(instance_id: "others").try(:shares) }.to(200)
      end
    end
  end
end
