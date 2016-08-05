require 'spec_helper'

describe 'ApiDetail' do
  describe 'instance methods' do
    let(:api)  { Trading::ApiDetail.new(exec_details_hash(@basket.try(:id), @order.try(:id))["exec"].select {|e| e["type"] == "API"}.inject([]) { |sum, detail| sum << detail }[0], @user) }
    
    before :each do
      @user = create(:binding_user)
      create(:account_value, user_id: @user.id, key: "LastTotalCash", value: 1234324234, currency: "BASE")
      @basket = create(:basket_with_appl_and_yhoo)
      @order = build(:order, real_cost: 2, instance_id: @basket.id, basket_id: @basket.id, user_id: @user.id, order_details_attributes: order_details_attributes(@basket))
      @order.save(validate: false)
    end
    
    it 'create one api order' do
      api.create_api_order
      expect(ApiExec.count).to eq 1
    end
    
    it 'is valid' do
      expect(api.valid?).to eq true
    end
    
    it 'returns api attrs' do
      expect(api.send(:api_attrs)).to be_a_kind_of(Hash)
    end
    
    it 'contains key instance_id' do
      expect(api.send(:api_attrs)).to include(instance_id: @basket.id.to_s)
    end
    
    it 'returns instance_id' do
      expect(api.send(:instance_id)).to eq @basket.id.to_s
    end
    
    it 'returns order id' do
      expect(api.send(:real_order_id)).to eq @order.id.to_s
    end
    
    it 'invoked sell_reconciled_attrs' do
      api.stub(:sell_reconciled_attrs).and_return(nil)
      api.send(:reconciled_attrs)
      expect(api).to have_received(:sell_reconciled_attrs)
    end
    
    it 'invoked buy_reconciled_attrs' do
      api.stub(:side).and_return("BOT")
      api.stub(:buy_reconciled_attrs).and_return(nil)
      api.send(:reconciled_attrs)
      expect(api).to have_received(:buy_reconciled_attrs)
    end
    
    it 'returns sell_reconciled_attrs' do
      expect(api.send(:sell_reconciled_attrs)).to eq ({ shares: -1000, pending_shares: -1000 })
    end
    
    it 'returns buy_reconciled_attrs' do
      api.stub(:side).and_return("BOT")
      expect(api.send(:buy_reconciled_attrs)).to eq ({ shares: 1000, average_cost: 15.54 })
    end
    
    context 'SLD' do
      it 'returns reconciled_shares' do
        expect(api.send(:reconciled_shares)).to eq -1000
      end
    end
    
    context 'BOT' do
      it 'returns reconciled_shares' do
        api.stub(:side).and_return("BOT")
        expect(api.send(:reconciled_shares)).to eq 1000
      end
    end
    
    it 'returns pending_shares' do
      expect(api.send(:pending_shares)).to eq -1000
    end
    
    context 'SLD' do
      it 'returns true' do
        expect(api.send(:sell?)).to eq true
      end
    end
    
    context 'BOT' do
      it 'returns false' do
        api.stub(:side).and_return("BOT")
        expect(api.send(:sell?)).to eq false
      end
    end
    
    it 'returns position_avg_cost' do
      expect(api.send(:position_avg_cost).abs).to eq 15.54
    end
    
    it 'returns total_cost' do
      expect(api.send(:total_cost)).to eq 15540
    end
    
    it 'returns this_time_cost' do
      expect(api.send(:this_time_cost)).to eq 15540
    end
    
    it 'returns this_time_filled' do
      expect(api.send(:this_time_filled)).to eq 1000
    end
    
    it 'returns previous_total_filled' do
      expect(api.send(:previous_total_filled)).to eq 0
    end
    
    it 'returns previous_total_cost' do
      expect(api.send(:previous_total_cost)).to eq 0
    end
    
    it 'returns est_shares' do
      expect(api.send(:est_shares)).to eq 1000
    end
    
    it 'returns initial_pending_shares' do
      expect(api.send(:initial_pending_shares)).to eq 0
    end
    
    it 'returns initial_shares' do
      expect(api.send(:initial_shares)).to eq 0
    end
    
    it 'returns position_previous_cost' do
      expect(api.send(:position_previous_cost)).to eq 0
    end
    
    it 'returns position_attrs' do
      expect(api.send(:position_attrs)).to have_key :basket_id
    end
    
    subject { api.reconcile }
    it 'change order_detail status to filled' do
      expect { subject }.to change { api.instance_variable_get("@order_detail").status }.from("ready").to("filled")
    end
    
    it 'change order_detail real_shares' do
      expect { subject }.to change { api.instance_variable_get("@order_detail").real_shares }.from(nil).to(1000)
    end
    
    it 'change order_detail real_cost' do
      expect { subject }.to change { api.instance_variable_get("@order_detail").real_cost }.from(nil).to(15540)  
    end
    
    it 'change position shares' do
      expect { subject }.to change { api.instance_variable_get("@position").shares }.from(nil).to(-1000)  
    end
    
    context 'SLD' do
      it 'does not change position average_cost' do
        expect { subject }.to_not change { api.instance_variable_get("@position").average_cost }
      end
      
      it 'changes pending shares' do
        expect { subject }.to change { api.instance_variable_get("@position").pending_shares }.from(nil).to(-1000)
      end
    end
    
    context 'BOT' do
      before :each do
        api.stub(:side).and_return("BOT")
      end
      it 'changes position average_cost' do
        expect { subject }.to change { api.instance_variable_get("@position").average_cost }.from(0).to(15.54)
      end
      
      it 'does not change position pending_shares' do
        expect { subject }.to_not change { api.instance_variable_get("@position").pending_shares }
      end
    end
  end
end
