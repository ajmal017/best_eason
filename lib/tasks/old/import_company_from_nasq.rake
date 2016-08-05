namespace :caishuo do
  desc 'import company name from nasq'
  task :import_company_from_nasq => :environment do
    company_names = File.readlines(Rails.root.join("data", "company_list")).map(&:chomp)
    company_set = Redis::Set.new('company_list')
    company_set << company_names
  end
end
