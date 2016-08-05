require 'spec_helper'

describe 'TwsDetail' do
  describe 'instance methods' do
    let(:tws)  { Trading::TwsDetail.new(exec_details_hash(@basket.try(:id), @order.try(:id))["exec"].select {|e| e["type"] == "TWS"}.inject([]) { |sum, detail| sum << detail }[0], @user) }
    
    before :each do
      @user = create(:binding_user)
      create(:account_value, user_id: @user.id, key: "LastTotalCash", value: 1234324234, currency: "BASE")
      @basket = create(:basket_with_appl_and_yhoo)
      @order = build(:order, real_cost: 2, instance_id: @basket.id, basket_id: @basket.id, user_id: @user.id, order_details_attributes: order_details_attributes(@basket))
      @order.save(validate: false)
    end
    
    subject { tws.create_tws_order }
    it 'create one tws' do
      expect { subject }.to change(TwsExec, :count).by(1)
    end
    
  end
end
