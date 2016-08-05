require 'spec_helper'

describe 'OrderStatusHandler' do
  describe 'instnce methods' do
    let(:order_status)  { Trading::OrderStatusHandler.new(order_status_hash(@basket.id, @order.id, "BOT")[:filled]) }
    
    before :each do
      @user = create(:binding_user)
      create(:account_value, user_id: @user.id, key: "LastTotalCash", value: 1234324234, currency: "BASE")
      @basket = create(:basket_with_appl_and_yhoo)
      @order = create(:order, real_cost: 2, instance_id: @basket.id, basket_id: @basket.id, user_id: @user.id, type: OrderBuy, order_details_attributes: order_details_attributes(@basket))
      
      # est_cost_of_usd依赖于redis，这里将其stub掉
      order_status.instance_variable_get("@order_detail").stub(:est_cost_of_usd).and_return(234)
    end
  
    it 'get instance_id from basket_id' do
      expect(order_status.send(:instance_id)).to eq @basket.id.to_s
    end
  
    it 'get order_id from basket_id' do
      expect(order_status.send(:real_order_id)).to eq @order.id.to_s
    end
  
    it 'get sequence of order log' do
      expect(order_status.send(:sequence)).to eq 1
    end
  
    it 'create one order log' do
      order_status.send(:create_order_log)
      expect(OrderLog.count).to eq 1
    end
  
    it 'returns inital pending shares' do
      expect(order_status.send(:initial_pending_shares)).to eq(0)
    end
  
    it 'returns already filled shares' do
      expect(order_status.send(:already_filled)).to eq(1000)
    end
  
    subject { order_status.send(:update_pending_shares) }
    it 'changes pending_shares' do
      expect { subject }.to change { order_status.send(:position).pending_shares }.from(nil).to(-1000)
    end
  
    it 'returns pending shares' do
      expect(order_status.send(:pending_shares)).to eq(-1000)
    end
  
    describe 'udpate position' do
      context 'SLD' do
        it 'has invoked update_pending_shares' do
          order_status.stub(:side).and_return("SLD")
          order_status.stub(:update_pending_shares).and_return(nil)
          order_status.send(:update_position)
          expect(order_status).to have_received(:update_pending_shares)
        end
      end
    
      subject { order_status.send(:update_position) }
      context 'BOT' do
        it 'does not change position pending_shares' do
          expect { subject }.to_not change { order_status.send(:position).pending_shares }
        end
    
        it 'changes posiiton shares' do
          expect { subject }.to change { order_status.send(:position).shares }.from(nil).to(1000)
        end
    
        it 'changes position avg_cost' do
          expect { subject }.to change { order_status.send(:position).average_cost }.from(0).to(6.08)
        end
      end
    end
  
    describe 'cancelled perform' do
      subject { order_status.send(:cancelled_perform) }
    
      context 'filled 0' do
        it 'changes order_detail status to :cancelled' do
          order_status.stub(:already_filled).and_return(0)
          expect { subject }.to change { order_status.instance_variable_get("@order_detail").status }.from("ready").to("cancelled")
        end  
      
        it 'has invoked update_posiiton' do
          order_status.stub(:update_position).and_return(nil)
          order_status.send(:cancelled_perform)
          expect(order_status).to have_received(:update_position)
        end
      end
    
      context 'filled some' do
        it 'changes order_detail status to :partial_filled' do
          expect { subject }.to change { order_status.instance_variable_get("@order_detail").status }.from("ready").to("partial_filled")
        end  
      
        it 'has invoked update_posiiton' do
          order_status.stub(:update_position).and_return(nil)
          order_status.send(:cancelled_perform)
          expect(order_status).to have_received(:update_position)
        end
      end
    
    end
  
    describe 'filled perform' do
      subject { order_status.send(:filled_perform) }
    
      it 'changes order_detail status to :filled' do
        expect { subject }.to change { order_status.instance_variable_get("@order_detail").status }.from("ready").to("filled")
      end  
    
      it 'has invoked update_posiiton' do
        order_status.stub(:update_position).and_return(nil)
        order_status.send(:cancelled_perform)
        expect(order_status).to have_received(:update_position)
      end
    end
  
    describe 'submitted perform' do
      subject { order_status.send(:submitted_perform) }
    
      it 'changes order_detail status to :filled' do
        expect { subject }.to change { order_status.instance_variable_get("@order_detail").status }.from("ready").to("submitted")
      end  
    
      it 'has invoked update_posiiton' do
        order_status.stub(:update_position).and_return(nil)
        order_status.send(:cancelled_perform)
        expect(order_status).to have_received(:update_position)
      end
    end
  
    describe 'inactive perform' do
      subject { order_status.send(:inactive_perform) }
    
      it 'changes order_detail status to :inactive' do
        expect { subject }.to change { order_status.instance_variable_get("@order_detail").status }.from("ready").to("inactive")
      end 
    end
  
    describe 'update_shares_and_avg_price' do
      it 'has invoked inactive_perform' do
        order_status.stub(:inactive_perform).and_return(nil)
        order_status.stub(:status).and_return("Inactive")
        order_status.send(:update_shares_and_avg_price)
        expect(order_status).to have_received(:inactive_perform)
      end
    
      it 'has invoked submitted_perform' do
        order_status.stub(:submitted_perform).and_return(nil)
        order_status.stub(:status).and_return("Submitted")
        order_status.send(:update_shares_and_avg_price)
        expect(order_status).to have_received(:submitted_perform)
      end
    
      it 'has invoked filled_perform' do
        order_status.stub(:filled_perform).and_return(nil)
        order_status.stub(:status).and_return("Filled")
        order_status.send(:update_shares_and_avg_price)
        expect(order_status).to have_received(:filled_perform)
      end
    
      it 'has invoked cancelled_perform' do
        order_status.stub(:cancelled_perform).and_return(nil)
        order_status.stub(:status).and_return("Cancelled")
        order_status.send(:update_shares_and_avg_price)
        expect(order_status).to have_received(:cancelled_perform)
      end
    end
  
    describe 'find or create a position' do
      subject { order_status.send(:position) }
    
      it 'create one position' do
        expect { subject }.to change(Position, :count).by(1)
      end
    end
  
    describe 'perform' do
      subject { order_status.perform }
      
      shared_examples :update_shares_cost do
        it 'create one order log' do
          expect {subject}.to change(OrderLog, :count).by(1)
        end
    
        it 'update order detail shares' do
          expect { subject }.to change { order_status.instance_variable_get("@order_detail").real_shares.to_i }.from(0).to(1000)
        end
    
        it 'update order detail real_cost' do
          expect { subject }.to change { order_status.instance_variable_get("@order_detail").real_cost.to_i }.from(0).to(6080)
        end
    
        it 'update position shares' do
          expect { subject }.to change { order_status.send(:position).shares.to_i }.from(0).to(1000)
        end
    
        it 'update position average_cost' do
          expect { subject }.to change { order_status.send(:position).average_cost }.from(0).to(6.08)
        end
      end
      
      context 'Filled message' do
        it 'update order detail status to :filled' do
          expect { subject }.to change { order_status.instance_variable_get("@order_detail").status }.from("ready").to("filled")
        end
        
        context 'BOT' do
          it 'does not change position pending_shares' do
            expect { subject }.to_not change { order_status.send(:position).pending_shares }
          end
        end
        
        context 'SLD' do
          it 'changes pending_shares' do
            order_status.stub(:side).and_return("SLD")
            expect { subject }.to change { order_status.send(:position).pending_shares.to_i }.from(0).to(-1000)
          end
        end
        
        it_behaves_like :update_shares_cost
      end
      
      context 'Cancelled message' do
        before :each do
          order_status.stub(:status).and_return("Cancelled")
        end
        
        context 'filled some' do
          it 'update order detail status to :cancelled' do
            expect { subject }.to change { order_status.instance_variable_get("@order_detail").status }.from("ready").to("partial_filled")
          end
        end
        
        context 'filled 0' do
          it 'update order detail status to :cancelled' do
            order_status.stub(:filled).and_return(0)
            expect { subject }.to change { order_status.instance_variable_get("@order_detail").status }.from("ready").to("cancelled")
          end
        end
        
        context 'BOT' do
          it 'does not change position pending_shares' do
            expect { subject }.to_not change { order_status.send(:position).pending_shares }
          end
        end
        
        context 'SLD' do
          it 'changes pending_shares' do
            order_status.stub(:side).and_return("SLD")
            order_status.stub(:remaining).and_return(2)
            expect { subject }.to change { order_status.send(:position).pending_shares.to_i }.from(0).to(-1002)
          end
        end
        
        it_behaves_like :update_shares_cost
      end
      
      context 'Submitted message' do
        before :each do
          order_status.stub(:status).and_return("Submitted")
        end
        
        it 'update order detail status to :submitted' do
          expect { subject }.to change { order_status.instance_variable_get("@order_detail").status }.from("ready").to("submitted")
        end
        
        context 'BOT' do
          it 'does not change position pending_shares' do
            expect { subject }.to_not change { order_status.send(:position).pending_shares }
          end
        end
        
        context 'SLD' do
          it 'changes pending_shares' do
            order_status.stub(:side).and_return("SLD")
            order_status.stub(:remaining).and_return(2)
            expect { subject }.to change { order_status.send(:position).pending_shares.to_i }.from(0).to(-1000)
          end
        end
        
        it_behaves_like :update_shares_cost
      end
      
      
      context 'Inactive message' do
        before :each do
          order_status.stub(:status).and_return("Inactive")
        end
        
        it 'update order detail status to :inactive' do
          expect { subject }.to change { order_status.instance_variable_get("@order_detail").status }.from("ready").to("inactive")
        end
        
        it 'create one order log' do
          expect {subject}.to change(OrderLog, :count).by(1)
        end
    
        it 'does not update order detail shares' do
          expect { subject }.to_not change { order_status.instance_variable_get("@order_detail").real_shares.to_i }
        end
    
        it 'does not update order detail real_cost' do
          expect { subject }.to_not change { order_status.instance_variable_get("@order_detail").real_cost.to_i }
        end
    
        it 'does not update position shares' do
          expect { subject }.to_not change { order_status.send(:position).shares.to_i }
        end
    
        it 'does not update position average_cost' do
          expect { subject }.to_not change { order_status.send(:position).average_cost }
        end
    
        context 'BOT' do
          it 'does not change position pending_shares' do
            expect { subject }.to_not change { order_status.send(:position).pending_shares }
          end
        end
        
        context 'SLD' do
          it 'changes pending_shares' do
            order_status.stub(:side).and_return("SLD")
            order_status.instance_variable_get("@order_detail").stub(:trade_type).and_return("OrderSell")
            expect { subject }.to change { order_status.send(:position).pending_shares.to_i }.from(0).to(-1000)
          end
        end
      end
    end
      
  end
end
