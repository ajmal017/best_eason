require 'spec_helper'

describe Order do
  describe 'state machine' do
    describe 'event expire' do
      
      subject { build(:order) }
      
      it 'respond to :expire' do
        expect(subject).to respond_to(:expire)
      end
    
      it 'respond to :expire!' do
        expect(subject).to respond_to(:expire!)
      end
    
      it 'defines :expired state' do
        expect(Order::STATE_EXPIRED).to eq(:expired)
      end
      
      it 'allows transitions from :confirmed to :expired' do
        od = build(:order, status: :confirmed)
        expect { od.expire }.to change { od.aasm.current_state }.from(:confirmed).to(:expired)
      end
    
      it 'denies transitions from :unconfirmed to :expired' do
        od = build(:order, status: :unconfirmed)
        expect { od.expire }.to raise_error(AASM::InvalidTransition)
      end
      
      it 'denies transitions from :completed to :expired' do
        od = build(:order, status: :completed)
        expect { od.expire }.to raise_error(AASM::InvalidTransition)
      end
      
      it 'denies transitions from :cancelled to :expired' do
        od = build(:order, status: :cancelled)
        expect { od.expire }.to raise_error(AASM::InvalidTransition)
      end
      
      it 'expire order_details after expire' do
        od = build(:order, status: :confirmed)
        allow(od).to receive(:expire_order_details)
        od.expire
        expect(od).to have_received(:expire_order_details)
      end
    end
  end
  
  describe "validates" do
    it "is valid with a instance_id, basket_id, user_id, est_cost and basket_mount" do
      expect(build(:order)).to be_valid
    end
  
    it "is invalid without instance_id on update" do
      expect(create(:order).update_attributes(instance_id: nil)).to_not be_true
    end
  
    it "is invalid without user_id" do
      expect(build(:order, user_id: nil)).to have(1).errors_on(:user_id)
    end
  
    it "is valid with numericality est_cost" do
      expect(build(:order, est_cost: 23.0)).to be_valid
    end
  
    it "is valid with numericality basket_mount" do
      expect(build(:order, basket_mount: 12)).to be_valid
    end
  
    it "is invalid with non-numericality basket_mount" do
      expect(build(:order, basket_mount: "non-numericality")).to have(1).errors_on(:basket_mount)
    end
  
    it "is invalid with basket_mount lower than 0" do
      expect(build(:order, basket_mount: -1)).to have(1).errors_on(:basket_mount)
    end
  end

  describe "callbacks" do
    context "set_order_stock_shares_log" do
      it "create order_stock_shares log" do
        stock_1 = create(:base_stock_appl)
        stock_2 = create(:base_stock_yhoo)
        user = create(:user)
        basket = create(:basket)
        order_params = {"basket_mount"=>"1", "basket_id"=>basket.id, "order_details_attributes"=>
                    {"0"=>{"base_stock_id"=>stock_1.id, "est_shares"=>"1"},
                     "1"=>{"base_stock_id"=>stock_2.id, "est_shares"=>"5"}}}
        order = OrderBuy.new(order_params.merge(:user_id => user.id))
        expect{order.save}.to change(OrderStockShare, :count).by(2)
      end
    end
  end

  describe "scope" do
    describe "unconfirmed orders" do

      subject { Order.unconfirmed }

      before :each do
        @unconfirmed_order = create(:unconfirmed_order)
        @confirmed_order = create(:order)
      end

      it { should match_array([@unconfirmed_order]) }
    end
  end
  
  describe "get current real cost" do
    context "nil real cost" do
      it "returns 0" do
        expect(build(:order, real_cost: nil).current_real_cost).to eq 0
      end
    end
    
    context "not nil real cost" do
      it "returns real cost" do
        expect(build(:order, real_cost: 22.2).current_real_cost).to eq 22.2
      end
    end
  end
  
  describe "update current real cost" do
    it "update current real cost by filled and avg_fill_price" do
      real_cost = 22.2
      filled = 20
      avg_fill_price = 2.2
      order = build(:order, real_cost: real_cost)
      order.update_real_cost_and_count(filled, avg_fill_price)
      expect(order.real_cost).to eq real_cost + filled * avg_fill_price
    end
  end
  
end
