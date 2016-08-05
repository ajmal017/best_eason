module CaGrab

  class Base
    attr_accessor :response, :doc, :page

    def initialize(date, page = 1)
      @date = date
      @page = page
    end

    def fetch
      @response = RestClient.post(self.class::BASE_URL, default_params, proxy: Setting.proxy.url)
      @doc = Nokogiri::HTML(@response.body)
      parse_results { |infos| store(infos) }
      fetch_next_page
    end

    def default_params
      { date: @date.to_s(:db), maxNoOfPages: 10, pg_no: @page, recordsPerPage: 10, recordsToDisplay: 10 }
    end

    def fetch_next_page
      2.upto(total_pages.to_i).each { |page| self.class.new(@date, page).fetch } if can_fetch? 
    end

    def can_fetch?
      total_pages && @page == 1
    end

    def total_pages
      if @doc.css('.linktext div').text =~ /of (\d+) pages/
        $1
      end
    end

    def parse_results
      @doc.css('table.bordered:last tr').each do |line|
        next if first_line?(line)
        attrs = line.search('td').map{ |x| x.text.full_strip }
        $corp_logger.info("street **** " + attrs.inspect)
        yield attrs if block_given?
      end
    end

    def first_line?(line)
      line.search('td').text.starts_with?(default_field_flag)
    end
    
    def base_id_for(symbol)
      BaseStock.find_by(symbol: symbol).try(:id)
    end

    def format_for(str_date)
      Date.parse(str_date) rescue nil 
    end
  end

  class Dividend < Base
    BASE_URL = "http://zacks.thestreet.com/tools/dividends_calendar.php"
    
    def store(attrs)
      infos = { 
        symbol: attrs.at(0), company_name: attrs.at(1), amount: attrs.at(2), ex_div_date: format_for(attrs[4]), 
        record_date: format_for(attrs[5]), payable_date: format_for(attrs[6]), base_stock_id: base_id_for(attrs.at(0))
      }
      CaDividend.find_or_create_by(infos)
    end
    
    def default_field_flag
      'TickerCompany'
    end

  end

  class Split < Base
    BASE_URL = "http://zacks.thestreet.com/tools/splits_calendar.php"
    
    def store(attrs)
      infos = {
        symbol: attrs.at(0), factor: attrs.at(2), base_stock_id: base_id_for(attrs.at(0)), company_name: attrs.at(1), date: @date
      }
      CaSplit.find_or_create_by(infos)
    end

    def default_field_flag
      'TickerCompanySplit'
    end

  end

  class OriginBase
    
    attr_accessor :date, :response, :doc, :split_date

    def initialize(date)
      @date = date
    end

    def request_url
      self.class::BASE_URL + "&date=" + us_central_time.to_i.to_s
    end

    def us_central_time
      @date.to_s(:date).in_time_zone('Central Time (US & Canada)')
    end

    def fetch
      @response = RestClient.get(request_url, proxy: Setting.proxy.url)
      @doc = Nokogiri::HTML(@response.body)
      
      set_split_date

      parse_results { |infos| store(infos) }
    end

    def parse_results
      @doc.css('tbody tr').each do |line|
        attrs = line.search('td').map{ |x| x.text.full_strip }
        $corp_logger.info("origin **** " + attrs.inspect)
        yield attrs if block_given?
      end
    end

    def format_for(str_date)
      Date.strptime(str_date, '%m/%d/%Y') rescue nil
    end
    
    def base_id_for(symbol)
      BaseStock.find_by(symbol: symbol).try(:id)
    end

    def set_split_date
      @split_date = Date.parse(@doc.search('body h1').text().gsub('Splits', ''))
    rescue 
      @split_date = @date
    end
  
  end

  class OriginDividend  < OriginBase
    BASE_URL = "http://www.zacks.com/includes/classes/z2_class_calendarfunctions_data.php?calltype=eventscal&type=5"
       
    def store(attrs)
      infos = {
        symbol: attrs.at(0), amount: attrs.at(2), ex_div_date: format_for(attrs.at(4)), 
        payable_date: format_for(attrs.at(6)), base_stock_id: base_id_for(attrs.at(0))
      }
      dividend = CaDividend.find_or_initialize_by(infos)
      dividend.update(company_name: attrs.at(1)) if dividend.new_record? 
    end
 
  end

  class OriginSplit < OriginBase
    BASE_URL = "http://www.zacks.com/includes/classes/z2_class_calendarfunctions_data.php?calltype=eventscal&type=4"

    def store(attrs)
      infos = { symbol: attrs.at(0), date: @split_date, base_stock_id: base_id_for(attrs.at(0)) }
      split = CaSplit.find_or_initialize_by(infos)
      split.update(company_name: attrs.at(1), factor: attrs.at(3)) if split.new_record?
    end
  end

  class Hk
    BASE_URL = "http://www.etnet.com.hk/www/eng/stocks/ci_div_latest.php?column=-1&page="

    def initialize(page = 1)
      @page = page
    end

    def fetch
      @response = RestClient.get(BASE_URL + @page.to_s, proxy: Setting.proxy.url)
      @doc = Nokogiri::HTML(@response.body)
      parse_results { |attrs| store(attrs) }
      fetch_next_page
    end

    def parse_results
      @doc.css(".DivFigureContent tr[valign='top']").each do |line|
        next if first_line?(line)
        attrs = line.search('td').map{ |x| x.text.full_strip }
        yield attrs if block_given? 
      end  
    end

    def store(attrs)
      if is_split?(attrs[4])
        split_store(attrs) 
      elsif is_dividend?(attrs[4])
        dividend_store(attrs)  
      end
    end

    def dividend_store(attrs)
      infos = {
        symbol: transform_symbol(attrs[1]), amount: attrs[4],
        ex_div_date: format_for(attrs[5]), payable_date: format_for(attrs[7]),
        company_name: attrs[2], base_stock_id: base_id_for(transform_symbol(attrs[1]))
      }
      
      CaDividend.find_or_create_by(infos)
    end
      
    def split_store(attrs)
      infos = {
        symbol: transform_symbol(attrs.at(1)), factor: factor_for(attrs[4]),
        company_name: attrs.at(2), base_stock_id: base_id_for(transform_symbol(attrs.at(1))),
        date: format_for(attrs.at(5))
      }
      
      CaSplit.find_or_create_by(infos)
    end

    def transform_symbol(symbol)
      symbol.gsub(/^0+/, '') + '.HK'
    end

    def format_for(str_date)
      Date.parse(str_date) rescue nil
    end

    def base_id_for(symbol)
      BaseStock.find_by(symbol: symbol).try(:id)
    end

    def factor_for(str_factor)
      case
      when str_factor =~ /Bonus (\d+) for (\d+)/
        "#{$1.to_i + $2.to_i}:#{$2}"
      when (str_factor =~ /Consolidation (\d+) into (\d+)/) || (str_factor =~ /Split (\d+) into (\d+)/)
        $2 + ':' + $1
      end
    end

    def is_split?(str)
      str =~ /(^Bonus)|(^Split)|(^Consolidation)/
    end

    def is_dividend?(str)
      str =~ /Div/
    end

    def first_line?(line)
      line.search('td').text.starts_with?('Announcement')
    end
    
    def fetch_next_page
      2.upto(total_pages.to_i).each { |page| self.class.new(page).fetch } if can_fetch? 
    end

    def can_fetch?
      total_pages && @page == 1
    end

    def total_pages
      @doc.search(".DivFigureContent tr:last span:last").text.full_strip
    end
  end
end
