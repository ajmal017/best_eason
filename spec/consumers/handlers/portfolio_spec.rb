require 'spec_helper'

describe 'Portfolio' do
  describe 'instance methods' do
    describe 'perform' do
      let(:hash) { portfolio_hash }
      
      let(:portfolio) { CaishuoMQ::Consumer::Handler::UpdatePortfolio.new(hash) }
      
      subject { portfolio.perform }
      context 'stock exists' do
        before :each do
          create(:base_stock, ib_id: 10041)
        end
        context 'binding user not exists' do
          it { lambda { subject }.should raise_error(ActiveRecord::RecordNotFound) }
        end
  
        context 'user not exists' do
          before :each do
            create(:user_binding, broker_user_id: "DU186928", user: nil)
          end
    
          it { lambda { subject }.should raise_error(BindingUserError) }
        end
      end
      
      context 'stock not exists' do
        before :each do
          create(:user_binding)
        end
        
        it { lambda { subject }.should raise_error(ActiveRecord::RecordNotFound) }
      end
      
      context 'others position not exists' do
        before :each do
          @stock = create(:base_stock, ib_id: 10041)
          @ub = create(:user_binding)
          user = @ub.user
          user.positions << create(:position, shares: 5, base_stock_id: @stock.id, average_cost: 1.2)
          user.positions << create(:position, shares: 6, base_stock_id: @stock.id, average_cost: 1.3)
          user.positions << create(:position, shares: 7, base_stock_id: @stock.id, average_cost: 1.4)
        end
        
        let(:average_cost) { (portfolio_hash["position"] * portfolio_hash["averageCost"] - ( 1.2 * 5 + 1.3 * 6 + 1.4 * 7))/(portfolio_hash["position"].to_i - 5 - 6 - 7) }
        
        it 'create one position' do
          expect { subject }.to change(Position, :count).by(1)
        end
        
        it 'update the shares of position to (IB_position - caishuo_shares)' do
          expect { subject }.to change { Position.find_by(instance_id: "others").try(:shares) }.from(nil).to(portfolio_hash["position"].to_i - 5 - 6 - 7)
        end
        
        it 'change others position average_cost' do
          expect { subject }.to change { Position.find_by(instance_id: "others").try(:average_cost) }.to(average_cost.round(2))
        end
        
        context 'position_delta not exists' do
          it 'create one position_delta' do
            expect { subject }.to change(PositionDelta, :count).by(1)
          end
          
          it 'change position_delta average_cost to portfolio average_cost' do
            expect { subject }.to change{ PositionDelta.last.try(:average_cost) }.to(portfolio_hash["averageCost"])
          end
          
          it 'update the delta of the new created position_delta from nil to (others position changed)' do
            expect { subject }.to change { PositionDelta.last.try(:delta) }.from(nil).to((80 - 5 - 6 - 7) - 0)
          end

          it 'update the user_id of the new created position_delta with the id of binding user' do
            expect { subject }.to change { PositionDelta.last.try(:user_id) }.from(nil).to(@ub.user.id)
          end

          it 'update the base_stock_id of the new created position_delta with the base_stock_id corresponding to the contractId' do
            expect { subject }.to change { PositionDelta.last.try(:base_stock_id) }.from(nil).to(@stock.id)
          end
          
        end
        
        context 'position_delta exists' do
          before :each do
            @delta = create(:position_deltum, base_stock_id: @stock.id, user_id: @ub.user.id)
          end
          
          it 'change position_delta average_cost to portfolio average_cost' do
            expect { subject }.to change { @delta.reload.average_cost }.to(portfolio_hash["averageCost"])
          end
          
          it 'does not create position_delta' do
            expect { subject }.to change(PositionDelta, :count).by(0)
          end
          
          it 'update the delta of the position_delta to (others position changed)' do
            expect { subject }.to change { @delta.reload.delta }.to((80 - 5 - 6 - 7) - 0)
          end
        end
                
        it_behaves_like :create_reconcile_request, 62
      end
      
      context 'others position exists' do
        before :each do
          @stock = create(:base_stock, ib_id: 10041)
          @ub = create(:user_binding)
          user = @ub.user
          user.positions << create(:position, shares: 5, base_stock_id: @stock.id)
          user.positions << create(:position, shares: 6, base_stock_id: @stock.id)
          user.positions << create(:position, shares: 7, base_stock_id: @stock.id)
          create(:position, instance_id: "others", base_stock_id: @stock.id, user_id: @ub.user.id, shares: 3)
        end
        
        it 'does not create position' do
          expect { subject }.to_not change(Position, :count)
        end
        
        it 'update the shares of position to (IB_position - caishuo_shares)' do
          expect { subject }.to change { Position.find_by(instance_id: "others").try(:shares) }.from(3).to(portfolio_hash["position"].to_i - 5 - 6 - 7)
        end
        
        context 'position_delta not exists' do
          it 'create one position_delta' do
            expect { subject }.to change(PositionDelta, :count).by(1)
          end
          
          it 'update the delta of the new created position_delta from nil to (others position changed)' do
            expect { subject }.to change { PositionDelta.last.try(:delta) }.from(nil).to((80 - 5 - 6 - 7) - 3)
          end

          it 'update the user_id of the new created position_delta with the id of binding user' do
            expect { subject }.to change { PositionDelta.last.try(:user_id) }.from(nil).to(@ub.user.id)
          end

          it 'update the base_stock_id of the new created position_delta with the base_stock_id corresponding to the contractId' do
            expect { subject }.to change { PositionDelta.last.try(:base_stock_id) }.from(nil).to(@stock.id)
          end
        end
        
        context 'position_delta exists' do
          before :each do
            @delta = create(:position_deltum, base_stock_id: @stock.id, user_id: @ub.user.id)
          end
          
          it 'does not create position_delta' do
            expect { subject }.to change(PositionDelta, :count).by(0)
          end
          
          it 'update the delta of the position_delta to (others position changed)' do
            expect { subject }.to change { @delta.reload.delta }.to((80 - 5 - 6 - 7) - 3)
          end
        end
        
        it_behaves_like :create_reconcile_request, 59
      end
      
      context 'split exists' do
        before :each do
          @stock = create(:base_stock, ib_id: 10041)
          @ub = create(:user_binding)
          user = @ub.user
          user.positions << create(:position, shares: 5, base_stock_id: @stock.id)
          user.positions << create(:position, shares: 17, base_stock_id: @stock.id)
          user.positions << create(:position, shares: 15, base_stock_id: @stock.id)
          create(:position, instance_id: "others", base_stock_id: @stock.id, user_id: @ub.user.id, shares: 3)
          create(:ca_split, factor: '2:1', date: Time.now.in_time_zone('Eastern Time (US & Canada)').to_date)
        end

        context 'delta not changes' do
          it 'does not create reconcile_request' do
            expect { subject }.to_not change(ReconcileRequestList, :count)
          end
        end
      end
    end
  end
end