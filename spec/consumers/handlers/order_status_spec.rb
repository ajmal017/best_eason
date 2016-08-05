require 'spec_helper'

describe 'OrderStatus' do
  describe 'instance methods' do
    describe 'perform' do
      subject { order_status.perform }
      
      context 'order exists' do
        before :each do
          @user = create(:binding_user)
          @basket = create(:basket_with_appl_and_yhoo)
          @order = create(:order, real_cost: 2, instance_id: @basket.id, basket_id: @basket.id, user_id: @user.id, type: OrderBuy, order_details_attributes: order_details_attributes(@basket))
          @order.update_attributes(instance_id: @basket.id)
          @order.order_details.map { |d| d.update_attributes!(instance_id: @basket.id) } 
          @od2 = @order.order_details.last
        end
        
        let(:avg_price) { order_status_hash(@order.id, "BOT")[:submitted]["avgFillPrice"] }
        
        let(:order_detail) { @order.order_details.first }
        
        shared_examples :ignore_status do
          context 'other message' do
            let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "BOT")[:other]) }
            
            it 'does not chagne the status of order detail' do
              expect { subject }.to_not change { order_detail.reload.status }
            end
            
            it 'does not change the shares of order detail' do
              expect { subject }.to_not change { order_detail.reload.real_shares }
            end
            
            it 'does not change the real_cost of order detail' do
              expect { subject }.to_not change { order_detail.reload.real_cost }
            end
            
            it 'does not change the real_cost of order' do
              expect { subject }.to_not change { @order.reload.real_cost }
            end
            
            it 'does not create position' do
              expect { subject }.to_not change(Position, :count)
            end
          end
        end
        
        shared_examples :create_position do
          it 'create one position' do
            expect { subject }.to change(Position, :count).by(1)
          end
          
          it 'update the shares of the new created position' do
            expect { subject }.to change { Position.last.try(:shares) }.to filled.to_d
          end
          
          it 'update the average_cost of the new created position' do
            expect { subject }.to change { Position.last.try(:average_cost) }.to avg_price.to_d
          end
          
          it 'update other attributes of the new created position' do
            expect { subject }.to change { [Position.last.try(:user_id), Position.last.try(:basket_id), Position.last.try(:basket_mount)] }.to([@user.id, @basket.id, @order.basket_mount])
          end
        end
        
        shared_examples :does_nothing do
          it 'does not change the status of order detail' do
            expect { subject }.to_not change { order_detail.reload.status }
          end
          
          it 'does not change shares of order detail' do
            expect { subject }.to_not change { order_detail.reload.real_shares }
          end
          
          it 'does not change real_cost of order detail' do
            expect { subject }.to_not change { order_detail.reload.real_cost }
          end
          
          it 'does not change real_cost of order' do
            expect { subject }.to_not change { @order.reload.real_cost }
          end
        end
        
        context 'buy' do
          context 'current status ready' do
            context 'submitted message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "BOT")[:submitted]) }
          
              let(:filled) { order_status_hash(@basket.id, @order.id, "BOT")[:submitted]["filled"] }
              
              let(:ib_order_id) { order_status_hash(@basket.id, @order.id, "BOT")[:submitted]["orderId"] }
              
              let(:avg_price) { order_status_hash(@basket.id, @order.id, "BOT")[:submitted]["avgFillPrice"] }
          
              it 'change the status of order detail to :submitted' do
                expect { subject }.to change { order_detail.reload.status }.from("ready").to("submitted")
              end
          
              it 'change the shares of order detail' do
                expect { subject }.to change { order_detail.reload.real_shares }.from(nil).to(filled.to_d)
              end
          
              it 'change the real_cost of order detail' do
                expect { subject }.to change { order_detail.reload.real_cost }.from(nil).to(filled.to_i * avg_price.to_d )
              end
          
              it 'does not change the real_cost of order' do
                expect { subject }.to_not change { @order.reload.real_cost }
              end
              
              it 'create one order log' do
                expect { subject }.to change(OrderLog, :count).by(1)
              end
              
              it 'update filled of order log' do
                expect { subject }.to change { OrderLog.last.try(:filled) }.from(nil).to(filled.to_i)
              end
              
              it 'update cost of order log' do
                expect { subject }.to change { OrderLog.last.try(:cost) }.from(nil).to(filled.to_i * avg_price.to_d)
              end
              
              it 'update ib_order_id of order log' do
                expect { subject }.to change { OrderLog.last.try(:ib_order_id) }.from(nil).to(ib_order_id.to_i)
              end
              
              it_behaves_like :create_position
            end
          
            context 'filled message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "BOT")[:filled]) }
          
              let(:filled) { order_status_hash(@basket.id, @order.id, "BOT")[:filled]["filled"] }
              
              let(:ib_order_id) { order_status_hash(@basket.id, @order.id, "BOT")[:filled]["orderId"] }
              
              let(:avg_price) { order_status_hash(@basket.id, @order.id, "BOT")[:filled]["avgFillPrice"] }
          
              it 'change the status of order detail to :filled' do
                expect { subject }.to change { order_detail.reload.status }.from("ready").to("filled")
              end
          
              it 'change the shares of order detail' do
                expect { subject }.to change { order_detail.reload.real_shares }.from(nil).to(filled.to_d)
              end
          
              it 'change the real_cost of order detail' do
                expect { subject }.to change { order_detail.reload.real_cost }.from(nil).to(filled.to_i * avg_price.to_d )
              end
          
              it 'change the real_cost of order' do
                expect { subject }.to change { @order.reload.real_cost }.from(2.to_d).to( 2 + filled.to_i * avg_price.to_d )
              end
              
              it 'create one order log' do
                expect { subject }.to change(OrderLog, :count).by(1)
              end
              
              it 'update filled of order log' do
                expect { subject }.to change { OrderLog.last.try(:filled) }.from(nil).to(filled.to_i)
              end
              
              it 'update cost of order log' do
                expect { subject }.to change { OrderLog.last.try(:cost) }.from(nil).to(filled.to_i * avg_price.to_d)
              end
              
              it 'update ib_order_id of order log' do
                expect { subject }.to change { OrderLog.last.try(:ib_order_id) }.from(nil).to(ib_order_id.to_i)
              end
            
              it_behaves_like :create_position
            end
          
            context 'cancelled message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "BOT")[:cancelled]) }
          
              let(:filled) { order_status_hash(@basket.id, @order.id, "BOT")[:cancelled]["filled"] }
              
              let(:ib_order_id) { order_status_hash(@basket.id, @order.id, "BOT")[:submitted]["orderId"] }
              
              let(:avg_price) { order_status_hash(@basket.id, @order.id, "BOT")[:submitted]["avgFillPrice"] }
          
              it 'change the status of order detail to :cancelled' do
                expect { subject }.to change { order_detail.reload.status }.from("ready").to("cancelled")
              end
          
              it 'change the shares of order detail' do
                expect { subject }.to change { order_detail.reload.real_shares }.from(nil).to(filled.to_d)
              end
          
              it 'change the real_cost of order detail' do
                expect { subject }.to change { order_detail.reload.real_cost }.from(nil).to(filled.to_i * avg_price.to_d )
              end
          
              it 'change the real_cost of order' do
                expect { subject }.to change { @order.reload.real_cost }.from(2.to_d).to( 2 + filled.to_i * avg_price.to_d )
              end
              
              it 'create one order log' do
                expect { subject }.to change(OrderLog, :count).by(1)
              end
              
              it 'update filled of order log' do
                expect { subject }.to change { OrderLog.last.try(:filled) }.from(nil).to(filled.to_i)
              end
              
              it 'update cost of order log' do
                expect { subject }.to change { OrderLog.last.try(:cost) }.from(nil).to(filled.to_i * avg_price.to_d)
              end
              
              it 'update ib_order_id of order log' do
                expect { subject }.to change { OrderLog.last.try(:ib_order_id) }.from(nil).to(ib_order_id.to_i)
              end
            
              it_behaves_like :create_position
            end
          
            it_behaves_like :ignore_status
          end
        
          context 'current status submitted' do
            before :each do
              @order.order_details.first.update_attributes(status: :submitted)
              @order.order_details.first.update_attributes(real_shares: 100)
              @position = create(:position, user_id: @user.id, basket_id: @order.basket_id, instance_id: @order.instance_id, basket_mount: @order.basket_mount, base_stock_id: order_detail.base_stock_id, shares: 100)
              OrderLog.create(ib_order_id: 10000192, filled: 50, cost: 50 * 6.08)
              OrderLog.create(ib_order_id: 10000192, filled: 50, cost: 50 * 6.08)
            end
          
            context 'submitted message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "BOT")[:submitted2]) }
          
              let(:filled) { order_status_hash(@basket.id, @order.id, "BOT")[:submitted2]["filled"] }
              
              let(:ib_order_id) { order_status_hash(@basket.id, @order.id, "BOT")[:submitted2]["orderId"] }
              
              let(:avg_price) { order_status_hash(@basket.id, @order.id, "BOT")[:submitted2]["avgFillPrice"] }
              
              it 'does not change the status of order detail' do
                expect { subject }.to_not change { order_detail.reload.status }
              end
          
              it 'does not change the real_cost of order' do
                expect { subject }.to_not change { @order.reload.real_cost }
              end
            
              it 'change the shares of order detail' do
                expect { subject }.to change { order_detail.reload.real_shares }.from(100).to(filled.to_d)
              end
        
              it 'change the real_cost of order detail' do
                expect { subject }.to change { order_detail.reload.real_cost }.from(nil).to(filled.to_i * avg_price.to_d )
              end
              
              it 'create one order log' do
                expect { subject }.to change(OrderLog, :count).by(1)
              end
            
              it 'update filled of order log' do
                expect { subject }.to change { OrderLog.last.try(:filled) }.from(50).to(filled.to_i - 50 - 50)
              end
            
              it 'update cost of order log' do
                expect { subject }.to change { OrderLog.last.try(:cost) }.from((50 * 6.08).to_d).to(filled.to_i * avg_price.to_d - 50 * 6.08 - 50 * 6.08)
              end
            
              it 'does not create position' do
                expect { subject }.to_not change(Position, :count)
              end
            
              it 'changes the shares of position' do
                expect { subject }.to change { @position.reload.shares }.from(100).to(filled.to_d)
              end
            end
          
            context 'filled message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "BOT")[:filled]) }
          
              let(:filled) { order_status_hash(@basket.id, @order.id, "BOT")[:filled]["filled"] }
              
              let(:ib_order_id) { order_status_hash(@basket.id, @order.id, "BOT")[:filled]["orderId"] }
              
              let(:avg_price) { order_status_hash(@basket.id, @order.id, "BOT")[:filled]["avgFillPrice"] }
          
              it 'change the status of order detail to :filled' do
                expect { subject }.to change { order_detail.reload.status }.from("submitted").to("filled")
              end
            
              it 'change the shares of order detail' do
                expect { subject }.to change { order_detail.reload.real_shares }.from(100).to(filled.to_d)
              end
        
              it 'change the real_cost of order detail' do
                expect { subject }.to change { order_detail.reload.real_cost }.from(nil).to(filled.to_i * avg_price.to_d )
              end
        
              it 'change the real_cost of order' do
                expect { subject }.to change { @order.reload.real_cost }.from(2.to_d).to( 2 + filled.to_i * avg_price.to_d )
              end
              
              it 'create one order log' do
                expect { subject }.to change(OrderLog, :count).by(1)
              end
            
              it 'update filled of order log' do
                expect { subject }.to change { OrderLog.last.try(:filled) }.from(50).to(filled.to_i - 50 - 50)
              end
            
              it 'update cost of order log' do
                expect { subject }.to change { OrderLog.last.try(:cost) }.from((50 * 6.08).to_d).to(filled.to_i * avg_price.to_d - 50 * 6.08 - 50 * 6.08)
              end
          
              it 'does not create position' do
                expect { subject }.to_not change(Position, :count)
              end
            
              it 'changes the shares of position' do
                expect { subject }.to change { @position.reload.shares }.from(100).to(filled.to_d)
              end
            
            end
          
            context 'cancelled message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "BOT")[:cancelled]) }
          
              let(:filled) { order_status_hash(@basket.id, @order.id, "BOT")[:cancelled]["filled"] }
              
              let(:ib_order_id) { order_status_hash(@basket.id, @order.id, "BOT")[:cancelled]["orderId"] }
              
              let(:avg_price) { order_status_hash(@basket.id, @order.id, "BOT")[:cancelled]["avgFillPrice"] }
          
              it 'change the status of order detail to :cancelled' do
                expect { subject }.to change { order_detail.reload.status }.from("submitted").to("cancelled")
              end
          
              it 'change the shares of order detail' do
                expect { subject }.to change { order_detail.reload.real_shares }.from(100).to(filled.to_d)
              end
        
              it 'change the real_cost of order detail' do
                expect { subject }.to change { order_detail.reload.real_cost }.from(nil).to(filled.to_i * avg_price.to_d )
              end
        
              it 'change the real_cost of order' do
                expect { subject }.to change { @order.reload.real_cost }.from(2.to_d).to( 2 + filled.to_i * avg_price.to_d )
              end
              
              it 'create one order log' do
                expect { subject }.to change(OrderLog, :count).by(1)
              end
            
              it 'update filled of order log' do
                expect { subject }.to change { OrderLog.last.try(:filled) }.from(50).to(filled.to_i - 50 - 50)
              end
            
              it 'update cost of order log' do
                expect { subject }.to change { OrderLog.last.try(:cost) }.from((50 * 6.08).to_d).to(filled.to_i * avg_price.to_d - 50 * 6.08 - 50 * 6.08)
              end
            
              it 'does not create position' do
                expect { subject }.to_not change(Position, :count)
              end
            
              it 'changes the shares of position' do
                expect { subject }.to change { @position.reload.shares }.from(100).to(filled.to_d)
              end
            end
          
            it_behaves_like :ignore_status
          end
        
          context 'current status filled' do
            before :each do
              @order.order_details.first.update_attributes(status: :filled)
            end
          
            context 'submitted message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "BOT")[:submitted]) }
            
              it_behaves_like :does_nothing
            end
          
            context 'filled message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "BOT")[:filled]) }
            
              it_behaves_like :does_nothing
            end
          
            context 'cancelled message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "BOT")[:cancelled]) }
            
              it_behaves_like :does_nothing
            end
          
            it_behaves_like :ignore_status
          end
        
          context 'current status cancelled' do
            before :each do
              @order.order_details.first.update_attributes(status: :cancelled)
            end
          
            context 'submitted message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "BOT")[:submitted]) }
            
              it_behaves_like :does_nothing
            end
          
            context 'filled message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "BOT")[:filled]) }
            
              it_behaves_like :does_nothing
            end
          
            context 'cancelled message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "BOT")[:cancelled]) }
            
              it_behaves_like :does_nothing
            end
          
            it_behaves_like :ignore_status
          end
        end
        
        context 'sell' do
          before :each do
            @position = create(:position, user_id: @user.id, basket_id: @order.basket_id, instance_id: @order.instance_id, basket_mount: @order.basket_mount, base_stock_id: order_detail.base_stock_id, shares: 1020, pending_shares: 1000)
          end
          
          context 'current status ready' do
            context 'submitted message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "SLD")[:submitted]) }
          
              let(:filled) { order_status_hash(@basket.id, @order.id, "SLD")[:submitted]["filled"] }
              
              let(:ib_order_id) { order_status_hash(@basket.id, @order.id, "SLD")[:submitted]["orderId"] }
              
              let(:avg_price) { order_status_hash(@basket.id, @order.id, "SLD")[:submitted]["avgFillPrice"] }
              
              it 'change the status of order detail to :submitted' do
                expect { subject }.to change { order_detail.reload.status }.from("ready").to("submitted")
              end
          
              it 'change the shares of order detail' do
                expect { subject }.to change { order_detail.reload.real_shares }.from(nil).to(filled.to_d)
              end
          
              it 'change the real_cost of order detail' do
                expect { subject }.to change { order_detail.reload.real_cost }.from(nil).to(filled.to_i * avg_price.to_d )
              end
          
              it 'does not change the real_cost of order' do
                expect { subject }.to_not change { @order.reload.real_cost }
              end
              
              it 'create one order log' do
                expect { subject }.to change(OrderLog, :count).by(1)
              end
              
              it 'update filled of order log' do
                expect { subject }.to change { OrderLog.last.try(:filled) }.from(nil).to(filled.to_i)
              end
              
              it 'update cost of order log' do
                expect { subject }.to change { OrderLog.last.try(:cost) }.from(nil).to(filled.to_i * avg_price.to_d)
              end
              
              it 'update ib_order_id of order log' do
                expect { subject }.to change { OrderLog.last.try(:ib_order_id) }.from(nil).to(ib_order_id.to_i)
              end
              
              it 'change the pending_shares of position' do
                expect { subject }.to change { Position.last.try(:pending_shares) }.from(1000).to(1000 - filled.to_i)
              end
            end
            
            context 'filled message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "SLD")[:filled]) }
          
              let(:filled) { order_status_hash(@basket.id, @order.id, "SLD")[:filled]["filled"] }
              
              let(:ib_order_id) { order_status_hash(@basket.id, @order.id, "SLD")[:filled]["orderId"] }
              
              let(:avg_price) { order_status_hash(@basket.id, @order.id, "SLD")[:filled]["avgFillPrice"] }
              
              it 'change the status of order detail to :filled' do
                expect { subject }.to change { order_detail.reload.status }.from("ready").to("filled")
              end
          
              it 'change the shares of order detail' do
                expect { subject }.to change { order_detail.reload.real_shares }.from(nil).to(filled.to_d)
              end
          
              it 'change the real_cost of order detail' do
                expect { subject }.to change { order_detail.reload.real_cost }.from(nil).to(filled.to_i * avg_price.to_d )
              end
          
              it 'change the real_cost of order' do
                expect { subject }.to change { @order.reload.real_cost }.from(2.to_d).to( 2 + filled.to_i * avg_price.to_d )
              end
              
              it 'create one order log' do
                expect { subject }.to change(OrderLog, :count).by(1)
              end
              
              it 'update filled of order log' do
                expect { subject }.to change { OrderLog.last.try(:filled) }.from(nil).to(filled.to_i)
              end
              
              it 'update cost of order log' do
                expect { subject }.to change { OrderLog.last.try(:cost) }.from(nil).to(filled.to_i * avg_price.to_d)
              end
              
              it 'update ib_order_id of order log' do
                expect { subject }.to change { OrderLog.last.try(:ib_order_id) }.from(nil).to(ib_order_id.to_i)
              end
              
              it 'change the pending_shares of position' do
                expect { subject }.to change { Position.last.try(:pending_shares) }.from(1000).to(1000 - filled.to_i)
              end
            end
            
            context 'cancelled message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "SLD")[:cancelled]) }
          
              let(:filled) { order_status_hash(@basket.id, @order.id, "SLD")[:cancelled]["filled"] }
              
              let(:ib_order_id) { order_status_hash(@basket.id, @order.id, "SLD")[:cancelled]["orderId"] }
              
              let(:avg_price) { order_status_hash(@basket.id, @order.id, "SLD")[:cancelled]["avgFillPrice"] }
              
              let(:remaining) { order_status_hash(@basket.id, @order.id, "SLD")[:cancelled]["remaining"] }
              
              it 'change the status of order detail to :cancelled' do
                expect { subject }.to change { order_detail.reload.status }.from("ready").to("cancelled")
              end
          
              it 'change the shares of order detail' do
                expect { subject }.to change { order_detail.reload.real_shares }.from(nil).to(filled.to_d)
              end
          
              it 'change the real_cost of order detail' do
                expect { subject }.to change { order_detail.reload.real_cost }.from(nil).to(filled.to_i * avg_price.to_d )
              end
          
              it 'change the real_cost of order' do
                expect { subject }.to change { @order.reload.real_cost }.from(2.to_d).to( 2 + filled.to_i * avg_price.to_d )
              end
              
              it 'create one order log' do
                expect { subject }.to change(OrderLog, :count).by(1)
              end
              
              it 'update filled of order log' do
                expect { subject }.to change { OrderLog.last.try(:filled) }.from(nil).to(filled.to_i)
              end
              
              it 'update cost of order log' do
                expect { subject }.to change { OrderLog.last.try(:cost) }.from(nil).to(filled.to_i * avg_price.to_d)
              end
              
              it 'update ib_order_id of order log' do
                expect { subject }.to change { OrderLog.last.try(:ib_order_id) }.from(nil).to(ib_order_id.to_i)
              end
              
              it 'change the pending_shares of position' do
                expect { subject }.to change { Position.last.try(:pending_shares) }.from(1000).to(1000 - filled.to_i - remaining.to_i)
              end
            end
          end
          
          context 'current status submitted' do
            before :each do
              @order.order_details.first.update_attributes(status: :submitted)
              OrderLog.create(ib_order_id: 10000192, filled: 50, cost: 50 * 6.08)
              OrderLog.create(ib_order_id: 10000192, filled: 50, cost: 50 * 6.08)
            end
          
            context 'submitted message' do
              let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(order_status_hash(@basket.id, @order.id, "SLD")[:submitted2]) }
          
              let(:filled) { order_status_hash(@basket.id, @order.id, "SLD")[:submitted2]["filled"] }
              
              let(:ib_order_id) { order_status_hash(@basket.id, @order.id, "SLD")[:submitted2]["orderId"] }
              
              let(:avg_price) { order_status_hash(@basket.id, @order.id, "SLD")[:submitted2]["avgFillPrice"] }
              
              it 'does not change the status of order detail' do
                expect { subject }.to_not change { order_detail.reload.status }
              end
          
              it 'does not change the real_cost of order' do
                expect { subject }.to_not change { @order.reload.real_cost }
              end
              
              it 'change the pending_shares of position' do
                expect { subject }.to change { Position.last.reload.pending_shares }.from(1000).to(1000 + 50 + 50 - filled.to_i)
              end
            
              context 'real_shares < filled' do
                before :each do
                  @order.order_details.first.update_attributes(real_shares: 99)
                end
              
                it 'change the shares of order detail' do
                  expect { subject }.to change { order_detail.reload.real_shares }.from(99).to(filled.to_d)
                end
          
                it 'change the real_cost of order detail' do
                  expect { subject }.to change { order_detail.reload.real_cost }.from(nil).to(filled.to_i * avg_price.to_d )
                end
                
                it 'create one order log' do
                  expect { subject }.to change(OrderLog, :count).by(1)
                end
              
                it 'update filled of order log' do
                  expect { subject }.to change { OrderLog.last.try(:filled) }.from(50).to(filled.to_i - 50 - 50)
                end
              
                it 'update cost of order log' do
                  expect { subject }.to change { OrderLog.last.try(:cost) }.from((50 * 6.08).to_d).to(filled.to_i * avg_price.to_d - 50 * 6.08 - 50 * 6.08)
                end
              end
            
              context 'real_shares >=  filled' do
                before :each do
                  @order.order_details.first.update_attributes(real_shares: 131)
                end
              
                it 'does not change the shares of order detail' do
                  expect { subject }.to_not change { order_detail.reload.real_shares }
                end
              
                it 'does not change the real_cost of order detail' do
                  expect { subject }.to_not change { order_detail.reload.real_cost }
                end
              end
            
              it 'does not create position' do
                expect { subject }.to_not change(Position, :count)
              end
            
              it 'changes the shares of position' do
                expect { subject }.to change { @position.reload.shares }.from(1020).to(1020 - (filled.to_d - 50 - 50))
              end
            end
          end
        end
      end
    end
    
    describe 'find stock by symbol' do
      let(:hash) { {"sequence" => 1, "basketId"=>"76:78", "exchange"=>"SEHK", "symbol"=>"AAPL", "orderId"=>"10000192", "status"=>"Submitted", "filled"=>"100", "remaining"=>"900", "avgFillPrice"=>"6.08", "side" => "SLD", "permId"=>"650979143", "parentId"=>"0", "lastFillPrice"=>"6.08", "clientId"=>"13", "whyHeld"=>"null"} }
      let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(hash) }
      
      subject { order_status.stock }
      
      context 'stock exists' do
        before :each do
          create(:base_stock_appl, ib_symbol: "AAPL")
        end
      
        it { should be_kind_of(BaseStock) }
      end
      
      context 'stock not exists' do
        it { lambda { subject }.should raise_error(ActiveRecord::RecordNotFound) }
      end
    end
    
    describe 'find order_detail by instance_id,order_id and base_stock_id' do
      let(:order) { create(:order, basket_id: 76) }
      
      let(:stock) { create(:base_stock_appl, ib_symbol: "AAPL") }
      
      let(:hash) { {"sequence" => 1, "basketId"=>"76:#{order.id}", "exchange"=>"SEHK", "symbol"=>"AAPL", "orderId"=>"10000192", "status"=>"Submitted", "filled"=>"100", "remaining"=>"900", "avgFillPrice"=>"6.08", "side" => "SLD", "permId"=>"650979143", "parentId"=>"0", "lastFillPrice"=>"6.08", "clientId"=>"13", "whyHeld"=>"null"} }
      
      let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(hash) }
      
      subject { order_status.order_detail }
      
      context 'order_detail nots exists by instance_id' do
        before :each do
          create(:order_detail, stock: stock)
        end
        
        it { lambda { subject }.should raise_error(ActiveRecord::RecordNotFound) }
      end
      
      context 'order_detail exists' do
        before :each do
          create(:order_detail, stock: stock, order: order)
        end
        
        it { should be_kind_of(OrderDetail) }
      end
    end
    
    describe 'find or create position by instance_id,base_stock_id and user_id' do
      let(:order) { create(:order, basket_id: 76) }
      
      let(:stock) { create(:base_stock_appl, ib_symbol: "AAPL") }
      
      let(:hash) { {"sequence" => 1, "basketId"=>"76:#{order.id}", "exchange"=>"SEHK", "symbol"=>"AAPL", "orderId"=>"10000192", "status"=>"Submitted", "filled"=>"100", "remaining"=>"900", "avgFillPrice"=>"6.08", "side" => "SLD", "permId"=>"650979143", "parentId"=>"0", "lastFillPrice"=>"6.08", "clientId"=>"13", "whyHeld"=>"null"} }
      
      let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(hash) }
      
      subject { order_status.position }
      
      before :each do
        @order_detail = create(:order_detail, stock: stock, order: order)
      end
      
      context 'position exists' do
        before :each do
          create(:position, instance_id: order.instance_id, base_stock_id: stock.id, user_id: order.user_id, basket_id: 233)
        end
        
        it { should be_kind_of(Position) }
        
        it 'update the basket_id of position' do
          expect { subject }.to change { Position.last.try(:basket_id) }.from(233).to(@order_detail.basket_id)
        end
      end
      
      context 'position not exists' do
        it { should be_kind_of(Position) }
        
        it 'update the basket_id of position' do
          expect { subject }.to change { Position.last.try(:basket_id) }.from(nil).to(@order_detail.basket_id)
        end
      end
    end
    
    describe 'update_shares_and_avg_price' do
      
      let(:order) { create(:order, instance_id: 76) }
      
      let(:stock) { create(:base_stock_appl, ib_symbol: "AAPL") }
      
      let(:order_status) { CaishuoMQ::Consumer::Handler::OrderStatus.new(hash) }
      
      context 'status submitted' do
        let(:hash) { {"sequence" => 1, "basketId"=>"76:#{order.id}", "exchange"=>"SEHK", "symbol"=>"AAPL", "orderId"=>"10000192", "status"=>"Submitted", "filled"=>"100", "remaining"=>"900", "avgFillPrice"=>"6.08", "side" => "SLD", "permId"=>"650979143", "parentId"=>"0", "lastFillPrice"=>"6.08", "clientId"=>"13", "whyHeld"=>"null"} }
        
        it 'invocate submitted_perform' do
          order_status.stub(:submitted_perform).and_return(nil)
          order_status.update_shares_and_avg_price
          expect(order_status).to have_received(:submitted_perform)
        end
      end
      
      context 'status filled' do
        let(:hash) { {"sequence" => 1, "basketId"=>"76:#{order.id}", "exchange"=>"SEHK", "symbol"=>"AAPL", "orderId"=>"10000192", "status"=>"Filled", "filled"=>"100", "remaining"=>"900", "avgFillPrice"=>"6.08", "side" => "SLD", "permId"=>"650979143", "parentId"=>"0", "lastFillPrice"=>"6.08", "clientId"=>"13", "whyHeld"=>"null"} }
        
        it 'invocate filled_perform' do
          order_status.stub(:filled_perform).and_return(nil)
          order_status.update_shares_and_avg_price
          expect(order_status).to have_received(:filled_perform)
        end
      end
      
      context 'status cancelled' do
        let(:hash) { {"sequence" => 1, "basketId"=>"76:#{order.id}", "exchange"=>"SEHK", "symbol"=>"AAPL", "orderId"=>"10000192", "status"=>"Cancelled", "filled"=>"100", "remaining"=>"900", "avgFillPrice"=>"6.08", "side" => "SLD", "permId"=>"650979143", "parentId"=>"0", "lastFillPrice"=>"6.08", "clientId"=>"13", "whyHeld"=>"null"} }
        
        it 'invocate cancelled_perform' do
          order_status.stub(:cancelled_perform).and_return(nil)
          order_status.update_shares_and_avg_price
          expect(order_status).to have_received(:cancelled_perform)
        end
      end
    end
  end
end