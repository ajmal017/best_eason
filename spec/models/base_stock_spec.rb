require 'spec_helper'

describe BaseStock do
  describe "validates" do
    it "is valid with a symbol" do
      expect(build(:base_stock)).to be_valid
    end
    
    it "is invalid without symbol" do
      expect(build(:base_stock, symbol: nil)).to have(1).errors_on(:symbol)
    end
    
    context "update" do
      it "is invalid without datasource" do
        expect(create(:base_stock).update_attributes(data_source: nil)).to_not be_true
      end
    end
  end
  
  describe "scopes" do
    describe "filter created_at by day" do
      before :each do
        @one_days_ago_1 = create(:base_stock, created_at: 1.days.ago)
        @one_days_ago_2 = create(:base_stock, created_at: 1.days.ago)
        @two_days_ago = create(:base_stock, created_at: 2.days.ago)
      end
      context "matching a day" do
        it "returns an array of results that match" do
          expect(BaseStock.created_at_day(1.days.ago.to_date.to_s(:db))).to eq [@one_days_ago_1, @one_days_ago_2]
        end
      end
      
      context "non-matching day" do
        it "only returns stocks with the provided day" do
          expect(BaseStock.created_at_day(1.days.ago.to_date.to_s(:db))).to_not include @two_days_ago
        end
      end
    end
    
    describe "filter qualified stocks" do
      it "returns all the qualified stocks" do
        @one_days_ago_1 = create(:base_stock, created_at: 1.days.ago)
        @one_days_ago_2 = create(:base_stock, created_at: 1.days.ago)
        @two_days_ago = create(:base_stock, created_at: 2.days.ago)
        expect(BaseStock.searchable_stocks).to eq [@one_days_ago_1, @one_days_ago_2, @two_days_ago]
      end
    end
    
    describe "count stocks by exchange" do
      before :each do
        @nasdq_1 = create(:base_stock, exchange: 'NASDAQ')
        @nasdq_2 = create(:base_stock, exchange: 'NASDAQ')
        @sehk = create(:base_stock, exchange: 'SEHK')
      end
      
      it "returns the count of stocks of the nasdq exchange" do
        expect(BaseStock.nasdaq_count).to eq 2
      end
      
      it "returns the count of stocks of the sehk exchange" do
        expect(BaseStock.sehk_count).to eq 1
      end
      
      it "returns the count of stocks of the nyse exchange" do
        expect(BaseStock.nyse_count).to eq 0
      end
    end
    
    describe "filter by start id and end id" do
      it "returns an array of stocks between start_id and end_id" do
        @id_1 = create(:base_stock, created_at: 1.days.ago)
        @id_2 = create(:base_stock, created_at: 1.days.ago)
        @id_3 = create(:base_stock, created_at: 2.days.ago)
        expect(BaseStock.between(@id_1.id,@id_2.id)).to eq [@id_1, @id_2]
      end
    end
  end
  
  describe "singleton methods" do
    describe "open spreadsheet" do
      context "file type csv" do
        let(:path) { "#{Rails.root}/spec/files/base_stocks.csv" }
        let(:file) { File.new(path)}
        let(:csv_file) { ActionDispatch::Http::UploadedFile.new({tempfile: file, filename: path}) }
        it "return a Roo::CSV object" do
          expect(BaseStock.open_spreadsheet(csv_file)).to be_a(Roo::CSV)
        end
      end
      
      context "file type xlsx" do
        let(:path) { "#{Rails.root}/spec/files/base_stocks.xlsx" }
        let(:file) { File.new(path)}
        let(:xlsx_file) { ActionDispatch::Http::UploadedFile.new({tempfile: file, filename: path}) }
        it "return a Roo::Excelx object" do
          expect(BaseStock.open_spreadsheet(xlsx_file)).to be_a(Roo::Excelx)
        end
      end
      
      context "file type xls" do
        let(:path) { "#{Rails.root}/spec/files/base_stocks.xls" }
        let(:file) { File.new(path)}
        let(:xls_file) { ActionDispatch::Http::UploadedFile.new({tempfile: file, filename: path}) }
        it "return a Roo::Excel object" do
          expect(BaseStock.open_spreadsheet(xls_file)).to be_a(Roo::Excel)
        end
      end
      
      context "file type not knonw" do
        let(:path) { "#{Rails.root}/spec/files/base_stocks.xxx" }
        let(:file) { File.new(path)}
        let(:not_known_file) { ActionDispatch::Http::UploadedFile.new({tempfile: file, filename: path}) }
        it "raise an error" do
          expect { BaseStock.open_spreadsheet(not_known_file) }.to raise_error(RuntimeError)
        end
      end
    end
    
    describe "import chinese name of stocks" do
      let(:path) { "#{Rails.root}/spec/files/import_c_name.xlsx" }
      let(:file) { File.new(path)}
      let(:xlsx_file) { ActionDispatch::Http::UploadedFile.new({tempfile: file, filename: path}) }
      context "stock by symbol exists" do
        it "update stock AAPL's chinese name" do
          stock = create(:base_stock, symbol: 'AAPL', c_name: nil)
          BaseStock.import_c_name(xlsx_file)
          expect(stock.reload.c_name).to_not be_nil
        end
      end
      
      context "stock does not exists" do
        it "does not create new stock" do
          expect { BaseStock.import_c_name(xlsx_file) }.to change(BaseStock, :count).by(0)
        end
      end
    end
    
    describe "export stocks as csv" do
      it "returns all the stocks as a csv string" do
        appl = create(:base_stock, symbol: 'APPL')
        yahoo = create(:base_stock, symbol: 'YHOO')
        columns = BaseStock.column_names.join(",")
        appl_str = appl.attributes.values.map{|v| v.to_s}.join(",")
        yahoo_str = yahoo.attributes.values.map{|v| v.to_s}.join(",")

        expect(BaseStock.to_csv).to eq(columns + "\n" + appl_str + "\n" + yahoo_str + "\n")
      end
    end
  end
  
  describe "instance methods" do
    describe "update supplement attributes" do
      let(:stock) { build(:base_stock, exchange: "SEHK", data_source: nil, ib_symbol: nil) }
      before :each do
        stock.update_supplement_info("apple", "APPL", "ib", "NYSE", "APPL")
      end
      
      it "update stock's name" do
        expect(stock.name).to eq "apple"
      end
      
      it "update stock's ib_symbol" do
        expect(stock.reload.ib_symbol).to eq "APPL"
      end
      
      it "update stock's data_source" do
        expect(stock.data_source).to eq "ib"
      end
      
      it "update stock's exchange" do
        expect(stock.exchange).to eq "NYSE"
      end
      
      it "update stock's symbol" do
        expect(stock.symbol).to eq "APPL"
      end
    end
    
    describe "add one data source" do
      context "current data source nil" do
        it "returns the data source we passed" do
          expect(build(:base_stock, data_source: nil).add_data_source("ib")).to eq "ib"
        end
      end
      
      context "current data source not include the data source we passed" do
        it "join current data source with the data source we passed with ','" do
          expect(build(:base_stock, data_source: "yahoo").add_data_source("ib")).to eq "yahoo,ib"
        end
      end
      
      context "context" do
        
      end
    end
  end
end
