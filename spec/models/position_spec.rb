require 'spec_helper'

describe Position do
  describe "validates" do
    it "is valid with a basket_id and base_stock_id" do
      expect(build(:position)).to be_valid
    end
    
    it "is invalid without instance_id" do
      expect(build(:position, instance_id: nil)).to have(1).errors_on(:instance_id)
    end
    
    it "is invalid without base_stock_id" do
      expect(build(:position, base_stock_id: nil)).to have(1).errors_on(:base_stock_id)
    end
    
    # it { should validate_numericality_of(:average_cost) }
#
#it { should allow_value(nil).for(:average_cost) }
  end
  
  describe 'db_column_and_index' do
    it { should have_db_column(:average_cost).of_type(:decimal).with_options(:precision => 16, :scale => 2, :default => 0.0) }
  end
  
  describe "instance methods" do
    describe "returns current shares" do
      context "nil shares" do
        it "returns 0" do
          expect(build(:position, shares: nil).current_shares).to eq 0
        end
      end
      context "not nil shares" do
        it "returns current shares" do
          expect(build(:position, shares: 3).current_shares).to eq 3
        end
      end
    end
    
    describe "verifies whether the filled is greater than current shares" do
      it "returns true" do
        expect(build(:position, shares: 3).filled_gte_shares(4)).to be_true
      end
      it "returns false" do
        expect(build(:position, shares: 3).filled_gte_shares(2)).to_not be_true
      end
    end
    
    describe "update current shares" do
      it "updates current shares" do
        position = build(:position, shares: 3)
        position.update_shares_and_avg_price("BOT", 10, 2.2)
        expect(position.shares).to eq (3 + 10).to_d
      end
    end
    
    it "reconcile current shares" do
      position = build(:position, shares: 3)
      position.reconcile(2, 3.2, 2)
      expect(position.shares).to eq 2.to_d
    end
  end
  
  describe "singleton methods" do
    describe "find or create one position by instance_id and base_stock_id" do
      context "position exists" do
        it "does not create position" do
          position = create(:position)
          expect {Position.find_or_create_concurrently(position.instance_id, position.base_stock_id, position.user_id)}.to change(Position, :count).by(0)
        end
        
        it "returns the exist position" do
          position = create(:position)
          expect(Position.find_or_create_concurrently(position.instance_id, position.base_stock_id, position.user_id)).to eq position
        end
      end
      context "position not exists" do
        it "creates a position" do
          expect {Position.find_or_create_concurrently("fjdsjfsdjfsdjf", 2, 2)}.to change(Position, :count).by(1)
        end
        
        it "returns the exist position" do
          expect(Position.find_or_create_concurrently("fjdsjfsdjfsdjf", 2, 2)).to eq Position.find_by(instance_id: "fjdsjfsdjfsdjf", base_stock_id: 2)
        end
      end
    end
  end
end
