require 'spec_helper'

describe 'AccountValue' do
  describe 'instance methods' do
    describe 'perform' do
      subject { account_value.perform }
      
      context 'buying power' do
        let(:account_value) { CaishuoMQ::Consumer::Handler::UpdateAccountValue.new(account_summary_buying_power) }
        
        it_behaves_like :user_not_exists
      end
      
      context 'net liquidation' do
        let(:account_value) { CaishuoMQ::Consumer::Handler::UpdateAccountValue.new(account_summary_net_liquidation) }
        
        it_behaves_like :user_not_exists
      end
      
      context 'total cash balance' do
        let(:account_value) { CaishuoMQ::Consumer::Handler::UpdateAccountValue.new(account_summary_total_cash_balance) }
        
        it_behaves_like :user_not_exists
      end
      
      context 'exchange rate' do
        context 'user exists' do
          let(:exchange_rate) { {"key"=>"Currency", "value"=>"1.20", "currency"=>"USD", "accountName"=>"DU186928"} }
        
          let(:account_value) { CaishuoMQ::Consumer::Handler::UpdateAccountValue.new(exchange_rate) }
          
          before :each do
            @ub = create(:user_binding)
          end
          
          it 'does not create position' do
            expect { subject }.to_not change(Position, :count)
          end
          
          context 'exchange rate != 1.0' do
            it 'does not change base_currency of user_binding' do
              expect { subject }.to_not change { @ub.reload.base_currency }
            end
          end
          
          context 'exchange rate == 1.0' do
            let(:exchange_rate) { {"key"=>"Currency", "value"=>"1.0", "currency"=>"HKD", "accountName"=>"DU186928"} }
            
            it 'change base_currency of user_binding' do
              expect { subject }.to change { @ub.reload.base_currency }.to exchange_rate["currency"]
            end
          end
        end
      end
    end
  end
end
