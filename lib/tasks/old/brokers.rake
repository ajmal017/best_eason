namespace :brokers do
  desc "Broker初始化"
  task :load => :environment do

    prefix = "BroITN"
    broker_data = [
      {name: "test", cname: "恒生证券测试", master_account: "ITN_TEST", status: "new"},
      {name: "guangzhou", cname: "广州证券", master_account: "GUANZHOU_ZQ", status: "new"},
      {name: "zhongxin_jt", cname: "中信建投证券", master_account: "ZHONGXIN_JT_ZQ", status: "published"},
      {name: "shanxi", cname: "山西证券", master_account: "SHANGXIN_ZQ", status: "new"},
      {name: "dongguan", cname: "东莞证券", master_account: "DONGGUAN_ZQ", status: "new"},
      {name: "changcheng", cname: "长城证券", master_account: "CHANGCHENG_ZQ", status: "new"},
      {name: "wukuang", cname: "五矿证券", master_account: "WUKUANG_ZQ", status: "new"},
      {name: "wanlian", cname: "万联证券", master_account: "WANLIAN_ZQ", status: "new"},
      {name: "hengtai", cname: "恒泰证券", master_account: "HENGTAI_ZQ", status: "new"},
      {name: "caifu", cname: "财富证券", master_account: "CAIFU_ZQ", status: "new"},
      {name: "zheshang", cname: "浙商证券", master_account: "ZHESHANG_ZQ", status: "new"},
      {name: "dongbei", cname: "东北证券", master_account: "DONGBEI_ZQ", status: "published"},
      {name: "rixin", cname: "日信证券", master_account: "RIXIN_ZQ", status: "new"},
      {name: "shouchuang", cname: "首创证券", master_account: "SOUCHUANG_ZQ", status: "new"},
      {name: "xinshidai", cname: "新时代证券", master_account: "XINSHIDAI_ZQ", status: "new"},
      {name: "hongxin", cname: "宏信证券", master_account: "HONGXIN_ZQ", status: "new"},
      {name: "huaxin", cname: "华信证券", master_account: "HUAXIN_ZQ", status: "new"},
      {name: "zhongjin", cname: "中金证券", master_account: "ZHONGJIN_ZQ", status: "published"},
      {name: "debang", cname: "德邦证券", master_account: "DEBANG_ZQ", status: "new"},
      {name: "dongfang", cname: "东方证券", master_account: "DONGFANG_ZQ", status: "new"},
      {name: "donghai", cname: "东海证券", master_account: "DONGHAI_ZQ", status: "new"},
      {name: "dongwu", cname: "东吴证券", master_account: "DONGWU_ZQ", status: "published"},
      {name: "haitong", cname: "海通证券", master_account: "HAITONG_ZQ", status: "published"},
      {name: "huaan", cname: "华安证券", master_account: "HUANA_ZQ", status: "new"},
      {name: "xinan", cname: "西南证券", master_account: "XINAN_ZQ", status: "published"},
      {name: "zhonghang", cname: "中航证券", master_account: "ZHONGHANG_ZQ", status: "new"},
      {name: "zhongxin", cname: "中信证券", master_account: "ZHONGXIN_ZQ", status: "published"},
    ]

    broker_data.each do |a|
      a[:master_account] = "#{prefix}_#{a[:master_account]}"
      broker = Broker.new(a)
      broker.display = (a[:status] == "published")
      broker.market = "cn"
      broker.save
    end

    
  end


end