require 'spec_helper'

describe StockInfoCrawler do
  describe 'singleton methods' do
    describe 'get websites' do
      subject { StockInfoCrawler.websites }
      
      it { should be_kind_of(Array) }
      
      it 'returns an array that contains symbols of base_stocks' do
        create(:base_stock, ib_symbol: 'AAPL', symbol: 'AAPL')
        create(:base_stock, ib_symbol: 'YHOO', symbol: 'YHOO')
        create(:base_stock, exchange: 'SEHK', ib_symbol: '00700', symbol: '00700.HK')
        url = 'http://xueqiu.com/S/'
        expect(subject).to match_array [url + 'AAPL', url + 'YHOO', url + '00700']
      end
    end
  end
end
