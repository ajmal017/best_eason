namespace :p2p do
  desc "初始化p2p相关数据"
  task :init => :environment do
    # Broker
    unless Broker.exists?(master_account: 'BroP2P')
      Broker.create(name: 'p2p', cname: '炒股宝', status: 'p2p', master_account: 'BroP2P', market: 'cn', display: true)
    end

    # 收益策略
    # 关联 沪深300
    stock = BaseStock.csi300
    %w(up down).each do |type|
      p = P2pStrategy.new(base_type: 'index', staffer_id: Admin::Staffer.first.id, change_type: type, weight: 1)
      p.mentionable = stock
      p.save!
    end
  end
end
