namespace :elasticsearch do
  desc "初始化news的索引配置(会删除之前的索引)"
  task :create_news_index => :environment do
    client = ::ES::News.gateway.client
    index_name = ::ES::News.index_name

    client.indices.delete index: index_name rescue nil

    settings = ::ES::News.settings.to_hash
    mappings = ::ES::News.mappings.to_hash

    client.indices.create index: index_name,
                          body: {
                            settings: settings.to_hash,
                            mappings: mappings.to_hash }
    
  end
end

