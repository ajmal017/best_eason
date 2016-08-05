namespace :caishuo do
  desc "将users的空username置为默认值"
  task :fix_users_username => :environment do
    puts "====begin===="

    User.where(username: [nil, ""]).each(&:set_default_username)

    puts "END"
  end
end

