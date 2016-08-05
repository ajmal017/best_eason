namespace :caishuo do
  desc 'import landings'
  task :import_landings => :environment do 
    puts "开始导入"
    Landing.find_each do |landing|
      puts landing.id
      lead = Lead.find_or_create_by(email: landing.email)
      lead.update(landing_id: landing.id)
    end

    puts "END"
  end
end
