require 'spec_helper'

describe 'BasketStatus' do
  
  describe 'instance methods' do
    describe 'perform' do
      before :each do
        @user = create(:binding_user)
        @basket = create(:basket_with_appl_and_yhoo)
        @order = create(:order, real_cost: 2, instance_id: "4f643322-3022-4b18-a3eb-a9c5d47c1b27", basket_id: @basket.id, user_id: @user.id, order_details_attributes: order_details_attributes(@basket))
        create(:user_binding, broker_user_id: "DU186929", user_id: @user.id)
        @order.update_attributes(instance_id: @basket.id)
        @order.order_details.map { |d| d.update_attributes!(instance_id: @order.instance_id) } 
        @od1 = @order.order_details.first
        @od2 = @order.order_details.last
      end
      
      subject { basket_status.perform }
      
      context 'order_details exist' do
        let(:hash) { {"basketId"=>"#{@order.instance_id}:#{@order.id}", "order"=>[
          {"symbol"=>"AAPL", "orderId"=>"10000001"}, 
          {"symbol"=>"YHOO", "orderId"=>"10000004"}]} 
        }
  
        let(:basket_status) { CaishuoMQ::Consumer::Handler::BasketStatus.new(hash) }
        
        it 'update ib_order_id of all the order_details that match' do
          expect { subject }.to change { [@od1.reload.ib_order_id, @od2.reload.ib_order_id] }.from([nil,nil]).to([10000001,10000004])
        end
      end
      
      context 'basket status expired' do
        let(:hash) { {"basketId"=>"#{@basket.id}:#{@order.id}", "error"=>"Expired"} }
        
        let(:basket_status) { CaishuoMQ::Consumer::Handler::BasketStatus.new(hash) }
        
        it 'update all the status of order_details to :expired' do
          expect { subject }.to change { [@od1.reload.status, @od2.reload.status] }.from(["ready","ready"]).to(["expired", "expired"])
        end
        
        it 'update the status of order to :expired' do
          expect { subject }.to change { @order.reload.status }.from("confirmed").to("expired")
        end
      end
      
      context 'all order details not exist' do
        let(:hash) { {"basketId"=>"not_exists_basket_id:#{@order.id}", "order"=>[
          {"symbol"=>"AAPL", "orderId"=>"10000001"}, 
          {"symbol"=>"YHOO", "orderId"=>"10000004"}]} 
        }
  
        let(:basket_status) { CaishuoMQ::Consumer::Handler::BasketStatus.new(hash) }
        
        it 'does not update ib_order_id of the order_details' do
          expect { subject }.to_not change { [@od1.reload.ib_order_id, @od2.reload.ib_order_id] }
        end
      end
      
      context 'one order detail not exist' do
        let(:hash) { {"basketId"=>"#{@basket.id}:#{@order.id}", "order"=>[
          {"symbol"=>"AAPL", "orderId"=>"10000001"}, 
          {"symbol"=>"WHOO", "orderId"=>"10000004"}]} 
        }
        
        let(:basket_status) { CaishuoMQ::Consumer::Handler::BasketStatus.new(hash) }
        
        it 'does not update ib_order_id of the order_detail that not exist' do
          expect { subject }.to_not change { @od2.reload.ib_order_id }
        end
        
        it 'udpate ib_order_id of the order_detail that exist' do
          expect { subject }.to change { @od1.reload.ib_order_id }.from(nil).to(10000001)
        end
      end
    end
    
    describe 'orders' do
      context 'basket_status hash' do
        let(:hash) { {"basketId"=>"4f643322-3022-4b18-a3eb-a9c5d47c1b27", "order"=>[
          {"symbol"=>"AAPL", "orderId"=>"10000001"}, 
          {"symbol"=>"YHOO", "orderId"=>"10000004"}]} 
        }
        
        let(:basket_status) { CaishuoMQ::Consumer::Handler::BasketStatus.new(hash) }
        
        subject { basket_status.orders }
        
        it { should be_kind_of Array}
        
        it { should have_all_order_data_elements }
      end
      
      context 'nil order hash' do
        let(:hash) { {"basketId"=>"4f643322-3022-4b18-a3eb-a9c5d47c1b27"} }
  
        let(:basket_status) { CaishuoMQ::Consumer::Handler::BasketStatus.new(hash) }
        
        subject { basket_status.orders }
        
        it { should be_kind_of Array}

        it { should be_empty }
      end
    end
    
    describe 'error' do
      
      context 'have error' do
        let(:hash) { {"basketId"=>"4f643322-3022-4b18-a3eb-a9c5d47c1b27", "error"=>"Expired"} }
      
        let(:basket_status) { CaishuoMQ::Consumer::Handler::BasketStatus.new(hash) }
      
        subject { basket_status.error }
        
        it 'returns "Expired"' do
          expect(subject).to eq "Expired"
        end
      end
      
      context 'does not have error' do
        let(:hash) { {"basketId"=>"4f643322-3022-4b18-a3eb-a9c5d47c1b27"} }
      
        let(:basket_status) { CaishuoMQ::Consumer::Handler::BasketStatus.new(hash) }
      
        subject { basket_status.error }
        
        it 'returns nil' do
          expect(subject).to eq nil
        end
      end
    end
  end
end