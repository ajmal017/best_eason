require 'spec_helper'

describe 'AccountSummary' do
  describe 'instance methods' do
    describe 'perform' do
      context 'buying power' do
        let(:buying_power) { CaishuoMQ::Consumer::Handler::AccountSummary.new(account_summary_buying_power) }
        
        subject { buying_power.perform }
        
        it_behaves_like :user_not_exists
      end
      
      context 'net liquidation' do
        let(:net_liquidation) { CaishuoMQ::Consumer::Handler::AccountSummary.new(account_summary_net_liquidation) }
        
        subject { net_liquidation.perform }
        
        it_behaves_like :user_not_exists
      end
      
      context 'total cash value' do
        let(:total_cash_value) { CaishuoMQ::Consumer::Handler::AccountSummary.new(account_summary_total_cash_balance) }
        
        subject { total_cash_value.perform }
        
        it_behaves_like :user_not_exists
      end
    end
  end
end