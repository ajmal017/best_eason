require 'spec_helper'

describe 'OrderStatus' do
  describe 'instance methods' do
    describe 'work' do
      before :each do
        @user = create(:binding_user)
        @basket = create(:basket_with_appl_and_yhoo)
        @order = create(:order, status: :unconfirmed, real_cost: 2, instance_id: "4f643322-3022-4b18-a3eb-a9c5d47c1b27", basket_id: @basket.id, user_id: @user.id, order_details_attributes: order_details_attributes(@basket))
        create(:user_binding, broker_user_id: "DU186929", user_id: @user.id)
        @order.update_attributes(instance_id: "4f643322-3022-4b18-a3eb-a9c5d47c1b27")
        @order.order_details.map { |d| d.update_attributes!(instance_id: "4f643322-3022-4b18-a3eb-a9c5d47c1b27") } 
        @od1 = @order.order_details.first
        @od2 = @order.order_details.last
        allow_any_instance_of(OrderStatus).to receive(:success!).and_return("success")
        allow_any_instance_of(OrderStatus).to receive(:drop!).and_return("drop")
      end
      
      context 'basket messages' do
        context 'order exists' do
          let(:basket_message) { order_status_basket_message(@order.id) }
        
          subject { OrderStatus.new.work(basket_message) }
        
          it 'update the status of order' do
            expect { subject }.to change { @order.reload.status }.from("unconfirmed").to("confirmed")
          end
        
          it 'ack success to rabbit' do
            expect(subject).to eq "success"
          end
        end
        
        context 'order doesnot exists' do
          let(:other_message) { order_status_order_not_exist }
        
          it_behaves_like :not_precesss_message
        end
        
      end
  
      context 'other messages' do
        let(:other_message) { order_status_other_message }
        
        it_behaves_like :not_precesss_message
      end
    end
  end
end