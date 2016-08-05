class StockIndexCrawler
  def initialize(url)
    @url = url
  end
  
  def crawl
    get
    data_processing
    ::StockIndex.notify
  end
  
  def get
    @res || ( @res = Remote::Base.get(@url) )
  end
  
  def result
    get.body.chomp.split(";")
  end
  
  def djs_str
    result[0].split("=")[1]
  end
  
  def nasdq_str
    result[1].split("=")[1]
  end
  
  def bp_str
    result[2].split("=")[1]
  end
  
  def hs_str
    result[3].split("=")[1]
  end
  
  def data_processing
    ::StockIndex::INDEX_KEYS.each { |k, index_key| self.send("#{k}_data_processing", index_key, self.send("#{k}_str")) }
  end
  
  def djs_data_processing(index_key, multi_value)
    persistent( index_key, us_attrs(multi_value) )
  end
  
  def nasdq_data_processing(index_key, multi_value)
    persistent( index_key, us_attrs(multi_value) )
  end
  
  def bp_data_processing(index_key, multi_value)
    persistent( index_key, us_attrs(multi_value) )
  end
  
  def us_attrs(multi_value)
    { 
      index: multi_value.split(",")[1], 
      change: multi_value.split(",")[4], 
      percent: multi_value.split(",")[2]
    }
  end
  
  def hs_data_processing(index_key, multi_value)
    persistent( index_key, hs_attrs(multi_value) )
  end
  
  def hs_attrs(multi_value)
    { 
      index: multi_value.split(",")[6], 
      change: multi_value.split(",")[7], 
      percent: multi_value.split(",")[8] 
    }
  end
  
  def persistent(index_key, values)
    $redis.hmset(index_key, "index", Caishuo::Utils::Helper.number_to_delimited(values[:index]), "change", Caishuo::Utils::Helper.number_to_delimited(values[:change]), "percent", values[:percent])
  end
  
  def self.crawl
    self.new("http://hq.sinajs.cn/list=gb_dji,gb_ixic,gb_$inx,rt_hkHSI").crawl
  end

  
end