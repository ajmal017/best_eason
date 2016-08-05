require 'spec_helper'

describe OrderDetail do
  describe "validates" do
    it "is valid with a instance_id, base_stock_id, symbol, user_id, basket_id and order_id" do
      expect(build(:order_detail)).to be_valid
    end
    
    context "on update" do
      let(:order_detail) {create(:order_detail)}
      it "is invalid without instance_id on update" do
        expect(order_detail.update_attributes(instance_id: nil)).to_not be_true
      end
      it "is invalid without user_id on update" do
        expect(order_detail.update_attributes(user_id: nil)).to_not be_true
      end
    
      it "is invalid without order_id on update" do
        expect(order_detail.update_attributes(order_id: nil)).to_not be_true
      end
    end
    
    it "is valid with numericality real_cost" do
      expect(build(:order_detail, real_cost: 23)).to be_valid
    end
    
    it "is invalid with non-numericality real_cost" do
      expect(build(:order_detail, real_cost: 'sdfsd')).to have(1).errors_on(:real_cost)
    end
    
    it "is valid with numericality est_shares" do
      expect(build(:order_detail, est_shares: 12)).to be_valid
    end
    
    it "is invalid with non-numericality est_shares" do
      expect(build(:order_detail, est_shares: 'sdfsd')).to have(1).errors_on(:est_shares)
    end
    
    it "is valid with numericality est_cost" do
      expect(build(:order_detail, est_cost: 25)).to be_valid
    end
    
    it "is valid with numericality real_shares" do
      expect(build(:order_detail, real_shares: 12.3)).to be_valid
    end
    
    it "is invalid with non-numericality real_shares" do
      expect(build(:order_detail, real_shares: 'sdfsd')).to have(1).errors_on(:real_shares)
    end
  end

  describe "state machine" do
    let(:order_detail) { build(:order_detail) }
    
    it "starts with ready status" do
      expect(order_detail.aasm.current_state).to eq :ready
    end
    
    it "need to pass arguements to event submit" do
      expect { order_detail.submit }.to raise_error(ArgumentError)
    end
    
    it "need to pass arguements to event fill" do
      expect { order_detail.fill }.to raise_error(ArgumentError)
    end
    
    it "need to pass arguements to event cancell" do
      expect { order_detail.cancel }.to raise_error(ArgumentError)
    end
    
    it "need to pass arguements to event reconcile" do
      expect { order_detail.reconcile }.to raise_error(ArgumentError)
    end
    
    it 'respond to :expire' do
      expect(order_detail).to respond_to(:expire)
    end
    
    it 'respond to :expire!' do
      expect(order_detail).to respond_to(:expire!)
    end
    
    it 'defines :expired state' do
      expect(OrderDetail::STATE_EXPIRED).to eq(:expired)
    end
    
    it 'allows transitions from :ready to :expired' do
      expect { order_detail.expire }.to change { order_detail.aasm.current_state }.from(:ready).to(:expired)
    end
    
    it 'denies transitions from :submitted to :expired' do
      od = build(:order_detail, status: :submitted)
      expect { od.expire }.to raise_error(AASM::InvalidTransition)
    end
    
    it 'denies transitions from :filled to :expired' do
      od = build(:order_detail, status: :filled)
      expect { od.expire }.to raise_error(AASM::InvalidTransition)
    end
    
    it 'denies transitions from :cancelled to :expired' do
      od = build(:order_detail, status: :cancelled)
      expect { od.expire }.to raise_error(AASM::InvalidTransition)
    end
  end

  describe "instance methods" do
    it "returns est_shares as size" do
      expect(build(:order_detail, est_shares: 12).size).to eq 12
    end
    
    describe "updates real cost and real shares" do
      let(:order_detail) { build(:order_detail) }
      
      context "event submit" do
        subject { order_detail.submit(nil, 2, 3) }
        
        it "transitions from :ready to :submitted" do
          expect { subject }.to change { order_detail.aasm.current_state }.to(:submitted)
        end
        
        it "updates to a new real_cost" do
          expect { subject }.to change { order_detail.real_cost }.to(2*3)
        end
        
        it "updates to a new real_shares" do
          expect { subject }.to change { order_detail.real_shares }.to(2)
        end
        
        it "does not change the real_cost of its order" do
          expect { subject }.to_not change { order_detail.order.real_cost }
        end
        
        it 'does not change the order_details_complete_count of order' do
          expect { subject }.to_not change { order_detail.order.reload.order_details_complete_count }
        end
      end
      
      context "event fill" do
        subject { order_detail.fill(nil, 2, 3) }
        
        it "transitions from :ready to :filled" do
          expect { subject }.to change { order_detail.aasm.current_state }.to(:filled)
        end
        
        it "updates to a new real_cost" do
          expect { subject }.to change { order_detail.real_cost }.to 2*3
        end
        
        it "updates to a new real_shares" do
          expect { subject }.to change { order_detail.real_shares }.to 2
        end
        
        it "udpates the real_cost of its order" do
          expect { subject }.to change { order_detail.order.real_cost }.to 2*3
        end
        
        it 'plus the order_details_complete_count of order by 1' do
          expect { subject }.to change { order_detail.order.reload.order_details_complete_count }.by(1)
        end
      end
      
      context "event cancel" do
        subject { order_detail.cancel(nil, 2, 3) }
        
        it "transitions from :ready to :cancelled" do
          expect { subject }.to change { order_detail.aasm.current_state }.to(:cancelled)
        end
        
        it "updates to a new real_cost" do
          expect { subject }.to change { order_detail.real_cost }.to 2*3
        end
        
        it "updates to a new real_shares" do
          expect { subject }.to change { order_detail.real_shares }.to 2
        end
        
        it "udpates the real_cost of its order" do
          expect { subject }.to change { order_detail.order.real_cost }.to 2*3
        end
        
        it 'plus the order_details_complete_count of order by 1' do
          expect { subject }.to change { order_detail.order.reload.order_details_complete_count }.by(1)
        end
      end
    end
    
    describe "reconcile real cost and real shares" do
      let(:order_detail) { build(:order_detail, real_shares: 3, real_cost: 5, status: :submitted) }

      context "event reconcile" do
        before :each do
          order_detail.reconcile(nil, 5, 3)
        end
        
        it "transitions from :submitted to :filled" do
          expect(order_detail.aasm.current_state).to eq :filled
        end
        
        it "updates to a new real_cost" do
          expect(order_detail.real_cost).to eq 5*3
        end
        
        it "updates to a new real_shares" do
          expect(order_detail.real_shares).to eq 5
        end
        
        it "udpates the real_cost of its order" do
          expect(order_detail.order.real_cost).to eq 5*3
        end
      end
    end
    
    describe "verifies whether the filled is greater than current shares" do
      let(:order_detail) { build(:order_detail, real_shares: 5) }
      
      it "returns true" do
        expect(order_detail.filled_gte_shares(6)).to be_true
      end
      
      it "returns false" do
        expect(order_detail.filled_gte_shares(4)).to_not be_true
      end
    end
    
    describe "returns current shares" do
      context "real_shares nil" do
        it "returns 0" do
          expect(build(:order_detail, real_shares: nil).current_shares).to eq 0
        end  
      end
      
      context "real_shares not nil" do
        it "returns current shares" do
          expect(build(:order_detail, real_shares: 3).current_shares).to eq 3
        end  
      end
    end
  end
end
