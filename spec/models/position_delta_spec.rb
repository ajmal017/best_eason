require 'spec_helper'

describe PositionDelta do
  describe 'validates' do
    it { should validate_presence_of(:user_id) }
    
    it { should validate_presence_of(:base_stock_id) }
    
    it { should validate_numericality_of(:delta).only_integer }
    
    it { should validate_numericality_of(:average_cost) }
    
    it { should allow_value(nil).for(:average_cost) }
  end
  
  describe 'associations' do
    it { should belong_to(:user) }
    
    it { should belong_to(:base_stock) }
  end
  
  describe 'db_column_and_index' do
    it { should have_db_column(:delta).of_type(:integer).with_options(:default => 0) }
    
    it { should have_db_column(:average_cost).of_type(:decimal).with_options(:precision => 16, :scale => 2, :default => 0.0) }
    
    it { should have_db_index([:user_id, :base_stock_id]).unique(true) }
  end
end
