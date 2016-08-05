shared_examples :create_reconcile_request do |others_shares|
  context 'others shares changed' do
    context 'reconcile request not exists' do
      it 'create a new reconcile request' do
        expect { subject }.to change(ReconcileRequestList, :count).by(1)
      end
      
      it 'create a new reconcile request with user_id' do
        expect { subject }.to change { ReconcileRequestList.last.try(:user_id) }.from(nil).to(@ub.user.id)
      end
      
      it 'create a new reconcile request with broker_user_id' do
        expect { subject }.to change { ReconcileRequestList.last.try(:broker_user_id) }.from(nil).to(portfolio.account_name)
      end
      
      it 'create a new reconcile request with symbol' do
        expect { subject }.to change { ReconcileRequestList.last.try(:symbol) }.from(nil).to(@stock.ib_symbol)
      end
      
      it 'add the count of the user_binding by 1' do
        expect { subject }.to change { @ub.reload.count }.by(1)
      end
    end
    
    context 'reconcile request already exists' do
      before :each do
        create(:reconcile_request_list, user_id: @ub.user.id, symbol: "AAPL", broker_user_id: portfolio.account_name)
      end
      it 'does not create reconcile request' do
        expect { subject }.to change(ReconcileRequestList, :count).by(0)
      end
      it 'add the count of the user_binding by 1' do
        expect { subject }.to change { @ub.reload.count }.by(1)
      end
    end
  end
  
  context 'others shares not changed' do
    before :each do
      @ub.user.positions << create(:position, shares: others_shares, base_stock_id: @stock.id)
    end
    it 'does not create reconcile request' do
      expect { subject }.to change(ReconcileRequestList, :count).by(0)
    end
  end
end