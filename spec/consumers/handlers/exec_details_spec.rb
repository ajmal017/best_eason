require 'spec_helper'

describe 'ExecDetails' do
  describe 'instance methods' do
    let(:hash) { exec_details_hash(@basket.try(:id), @order.try(:id)) }
       
    let(:exec_details) { CaishuoMQ::Consumer::Handler::ExecDetails.new(hash) }
    
    describe 'perform' do
      before :each do
        @user = create(:binding_user)
        @basket = create(:basket_with_appl_and_yhoo)
        @order = create(:order, real_cost: 2, instance_id: @basket.id, basket_id: @basket.id, user_id: @user.id, order_details_attributes: order_details_attributes(@basket))
      end
      
      subject { exec_details.perform }
        
      context 'user binding not exists' do
        it { lambda { subject }.should raise_error(ActiveRecord::RecordNotFound) }
      end
      
      context 'user not exists' do
        before :each do
          create(:user_binding, broker_user_id: "DU186929", user_id: nil)
        end
        
        it { lambda { subject }.should raise_error(BindingUserError) }
      end
      
      context 'user exists' do
        before :each do
          @user_binding = create(:user_binding, broker_user_id: "DU186929", user_id: @user.id)
          @order.update_attributes(instance_id: @basket.id)
          @order.order_details.map { |d| d.update_attributes!(instance_id: @basket.id) } 
          @od1 = @order.order_details.first
          @od2 = @order.order_details.last
        end
        
        context 'position already exists' do
          before :each do
            @pos1 = create(:position, instance_id: @order.basket_id, base_stock_id: @basket.stocks.first.id, user_id: @user.id, shares: 2, pending_shares: 998)
            @od1.update_attributes(real_shares: 2)
            @pos2 = create(:position, instance_id: @order.basket_id, base_stock_id: @basket.stocks.last.id, user_id: @user.id, shares: 3, average_cost: 10)
            @od2.update_attributes(real_shares: 3, real_cost: 30)
          end
          
          context 'order detail status :ready' do
            it_behaves_like :update_all_posiitons
            
            it_behaves_like :public_behavior_bt_ready_and_submitted, :ready
            
            
          end
        
          context 'order detail status :submitted' do
            before :each do
              @order.order_details.map {|d| d.update_attributes(status: "submitted") }
              OrderLog.create(ib_order_id: 10000048, filled: 2, cost: 2 * 6.08)
            end
            
            it 'update shares of all the positions' do
              expect { subject }.to change { [@pos1.reload.shares.to_i, @pos2.reload.shares.to_i] }.from([2,3]).to([-996,1000])
            end
            
            it_behaves_like :public_behavior_bt_ready_and_submitted, :submitted
            
            it 'update pending_shares' do
              expect { subject }.to change { @pos1.reload.pending_shares }.from(998).to(0)
            end
            
            it 'update average_cost' do
              expect { subject }.to change { @pos2.reload.average_cost }.from(10).to(15.52)
            end
          end
        
          context 'order detail status :filled' do
            before :each do
              @order.order_details.first.update_attributes(status: "filled")
            end
            
            it_behaves_like :udpate_one_position, :filled
          
            it_behaves_like :public_behavior_bt_filled_and_cancelled, :filled
          end
        
          context 'order detail status :cancelled' do
            before :each do
              @order.order_details.first.update_attributes(status: "cancelled")
            end
            
            it_behaves_like :udpate_one_position, :cancelled
          
            it_behaves_like :public_behavior_bt_filled_and_cancelled, :cancelled
          end
        
          context 'tws_shares = position_delta' do
            before :each do
              @pos1.destroy
              @pos2.destroy
              create(:position, base_stock_id: @basket.stocks.first.id, user_id: @user.id, shares: 555)
              create(:position, base_stock_id: @basket.stocks.first.id, user_id: @user.id, shares: 45)
              create(:position_deltum, base_stock_id: @basket.stocks.first.id, user_id: @user.id, delta: 200)
            end
          
            it 'change user_binding to available' do
              expect { subject }.to change { @user_binding.reload.available }.from(false).to(true)
            end
          
            it 'does not add reconcile request to ReconcileRequestList' do
              expect { subject }.to change(ReconcileRequestList, :count).by(0)
            end
            
            it 'initialize reconcile level' do
              expect { subject }.to change { @user_binding.reload.count }.to(0)
            end
          end
        
          context 'tws_shares != position_delta' do
            before :each do
              @pos1.destroy
              @pos2.destroy
              create(:position, base_stock_id: @basket.stocks.first.id, user_id: @user.id, shares: 550)
              create(:position, base_stock_id: @basket.stocks.first.id, user_id: @user.id, shares: 40)
              create(:position_deltum, base_stock_id: @basket.stocks.first.id, user_id: @user.id, delta: 210)
            end
          
            it 'change user_binding to unavailable' do
              expect { subject }.to_not change { @user_binding.reload.available }
            end
          
            it 'add one reconcile request to ReconcileRequestList' do
              expect { subject }.to change(ReconcileRequestList, :count).by(1)
            end
            
            it 'promote reconcile level', focus: false do
              expect { subject }.to change { @user_binding.reload.count }.by(1)
            end
          end
        end
        
        context 'position not exists' do
          before :each do
            @od1.update_attributes(real_shares: 2)
            @od2.update_attributes(real_shares: 3, real_cost: 30)
          end
          context 'order detail status :ready' do
            it_behaves_like :create_all_positions
            
            it_behaves_like :public_behavior_bt_ready_and_submitted, :ready
          end
        
          context 'order detail status :submitted' do
            before :each do
              @order.order_details.map {|d| d.update_attributes(status: "submitted") }
            end
            
            it_behaves_like :create_all_positions
          
            it_behaves_like :public_behavior_bt_ready_and_submitted, :submitted
          end
        
          context 'order detail status :filled' do
            before :each do
              @order.order_details.first.update_attributes(status: "filled")
            end
            
            it_behaves_like :create_one_position
          
            it_behaves_like :public_behavior_bt_filled_and_cancelled, :filled
          end
        
          context 'order detail status :cancelled' do
            before :each do
              @order.order_details.first.update_attributes(status: "filled")
            end
            
            it_behaves_like :create_one_position
          
            it_behaves_like :public_behavior_bt_filled_and_cancelled, :cancelled
          end
          
          context 'tws_shares = position_delta' do
            before :each do
              create(:position_deltum, base_stock_id: @basket.stocks.first.id, user_id: @user.id, delta: 200)
            end
          
            it 'change user_binding to available' do
              expect { subject }.to change { @user_binding.reload.available }.from(false).to(true)
            end
          
            it 'does not add reconcile request to ReconcileRequestList' do
              expect { subject }.to change(ReconcileRequestList, :count).by(0)
            end
          end
          
          context 'tws_shares != position_delta' do
            before :each do
              create(:position_deltum, base_stock_id: @basket.stocks.first.id, user_id: @user.id, delta: 210)
            end
          
            it 'change user_binding to unavailable' do
              expect { subject }.to_not change { @user_binding.reload.available }
            end
          
            it 'add one reconcile request to ReconcileRequestList' do
              expect { subject }.to change(ReconcileRequestList, :count).by(1)
            end
          end
        end
      end
      
    end
    
    describe 'details' do
      context 'array exec' do
        subject { exec_details.details }
      
        it_behaves_like :hash_with_array_values
      end
      
      context 'hash exec' do
        let(:exec_hash) { exec_details_exec_hash }
       
        let(:exec_hash_details) { CaishuoMQ::Consumer::Handler::ExecDetails.new(exec_hash) }
      
        subject { exec_hash_details.details }
        
        it_behaves_like :hash_with_array_values
      end
      
      context 'nil exec' do
        let(:exec_nil) { {"subAccount"=>"DU186929"} }
       
        let(:exec_nil_details) { CaishuoMQ::Consumer::Handler::ExecDetails.new(exec_nil) }
      
        subject { exec_nil_details.details }
        
        it_behaves_like :hash_with_array_values
      end
    end
    
    
    describe 'api_details' do
      before :each do
        @user = create(:binding_user)
        @basket = create(:basket_with_appl_and_yhoo)
        @order = create(:order, real_cost: 2, instance_id: @basket.id, basket_id: @basket.id, user_id: @user.id, order_details_attributes: order_details_attributes(@basket))
      end

      subject { exec_details.api_details }

      it_behaves_like :type_and_ele_type
end
    
    describe 'tws_details' do
      subject { exec_details.tws_details }
      
      it_behaves_like :type_and_ele_type
    end
    
    describe 'array_details' do
      subject { exec_details.array_details }
      
      it { should be_kind_of(Array) }
      
      it { should have_all_array_elements }
      
      it { should satisfy {|v| v[0].first.is_a?(CaishuoMQ::Consumer::Handler::Detail) && v[1].first.is_a?(CaishuoMQ::Consumer::Handler::Detail)} }
    end
    
    describe 'account' do
      subject { exec_details.account }

      it { should eq "DU186929" }
    end
    
    describe 'hash_details' do
      let(:exec_hash) { exec_details_exec_hash }
       
      let(:exec_hash_details) { CaishuoMQ::Consumer::Handler::ExecDetails.new(exec_hash) }
      
      subject { exec_hash_details.hash_details }
      
      it { should be_kind_of(Array) }
      
      it { should have_all_array_elements }
      
      it { should include [] }
      
      it { should_not match_array [[],[]] }
      
      it { should satisfy {|v| v[0].first.is_a?(CaishuoMQ::Consumer::Handler::Detail) && v[1].first.blank?} }
    end
    
    
  end
end

describe 'Detail' do
  let(:hash) { exec_details_exec_hash["exec"] }
  
  describe 'respond to :key' do
    subject { CaishuoMQ::Consumer::Handler::Detail.new(hash) }
    
    [:type, :basket_id, :symbol, :contract_id, :account_name, :avg_price, :cum_quantity, :exec_exchange, :exec_id, :order_id, :perm_id, :price, :shares, :side, :time, :ev_rule, :ex_multiplier].each do |method|
      it { should respond_to method }
    end
  end
  
  
  describe 'return value of key' do
    let(:detail) { CaishuoMQ::Consumer::Handler::Detail.new(hash) }
    it 'returns the value of key type' do
      expect(detail.type).to eq hash["type"]
    end
    
    it 'returns the value of key basket_id' do
      expect(detail.basket_id).to eq hash["basketId"]
    end
  end
end