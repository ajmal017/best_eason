require 'spec_helper'

describe ReconcileRequestList do
  describe 'validates' do
    it 'is valid with a user_id' do
      expect(build(:reconcile_request_list)).to be_valid
    end
    
    it 'is invalid without user_id' do
      expect(build(:reconcile_request_list, user_id: nil)).to have(1).errors_on(:user_id)
    end
    
    subject { build(:reconcile_request_list) }
    
    it { should validate_uniqueness_of(:user_id) }
  end
  
  describe 'db_column_and_index' do
    it { should have_db_index(:user_id).unique(true) }
  end
  
  describe 'instance methods' do
    describe 'update_broker_user_id_and_symbol' do
      subject { rrl.update_broker_user_id_and_symbol(account_name, ib_symbol) }
      
      let(:account_name) { "whoami" }
    
      let(:ib_symbol) { "AAPL" }
      
      context 'have symbols' do
        context 'contains ib_symbol' do
          let(:rrl) { build(:reconcile_request_list, symbol: "AAPL,YHOO") }
        
          it 'does not change symbol' do
            expect { subject }.to_not change { rrl.symbol }
          end
        end
        
        context 'does not contains ib_symbol' do
          let(:rrl) { build(:reconcile_request_list, symbol: "MSFT,YHOO") }
        
          it 'adds ib_symbol to symbol' do
            expect { subject }.to change { rrl.symbol }.from("MSFT,YHOO").to("MSFT,YHOO,AAPL")
          end
        end
      end
      
      context 'does not have symbol' do
        let(:rrl) { build(:reconcile_request_list) }
      
        it 'adds ib_symbol to symbol' do
          expect { subject }.to change { rrl.symbol }.from(nil).to("AAPL")
        end
      end
    end
  end
  
  describe 'singleton methods' do
    describe 'publish reoncile request message' do
      before :each do
        Publisher.stub(:publish).and_return(nil)
      end
      
      context 'requests exist' do
        before :each do
          @first = create(:reconcile_request_list, created_at: (Setting.reconcile_delay.to_i + 1).minutes.ago) 
          @last = create(:reconcile_request_list, user_id: 5, broker_user_id: "DU186929", created_at: (Setting.reconcile_delay.to_i + 1).minutes.ago)
          @message1 = {"advAccount" => "DI186927", "subAccount" => @first.broker_user_id}.to_xml(root: "requestExecutions")
          @message2 = {"advAccount" => "DI186927", "subAccount" => @last.broker_user_id}.to_xml(root: "requestExecutions")
        end
        
        context 'request created reconcile_delay minutes ago' do
          it 'publish n messages with n equals to the count of requests' do
            ReconcileRequestList.publish
            expect(Publisher).to have_received(:publish).twice
          end
          
          it 'delete the requests which have been published' do
            expect { ReconcileRequestList.publish }.to change(ReconcileRequestList, :count).by(-2)
          end
          
          it 'publish message with correct xml content' do
            ReconcileRequestList.publish
            expect(Publisher).to have_received(:publish).with(@message1)
            expect(Publisher).to have_received(:publish).with(@message2)
          end
        end
        context 'has a request created within reconcile_delay minutes' do
          it 'does not publish message corresponding to the request' do
            create(:reconcile_request_list, user_id: 3, broker_user_id: "DU186930")
            message = {"advAccount" => "DI186927", "subAccount" => "DU186930"}.to_xml(root: "requestExecutions")
            
            ReconcileRequestList.publish
            expect(Publisher).to_not have_received(:publish).with(message)
          end
          
          it 'delete the requests which have been published' do
            expect { ReconcileRequestList.publish }.to change(ReconcileRequestList, :count).by(-2)
          end
          
          it 'publish (n - 1) messages' do
            create(:reconcile_request_list, user_id: 3, broker_user_id: "DU186930")
            ReconcileRequestList.publish
            expect(Publisher).to have_received(:publish).twice
          end
        end
      end
      
      context 'request not exists' do
        it 'does not publish message' do
          ReconcileRequestList.publish
          expect(Publisher).to_not have_received(:publish)
        end
      end
    end
  end
end
