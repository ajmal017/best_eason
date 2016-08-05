namespace :banners do
  desc "热点首页banners，原来无large规格图片，发版前做初始化"
  task :cp_large_version => :environment do
    puts Recommend.banners.keys.join(", ")
    Upload::Recommend.where(id: Recommend.banners.keys).each do |ur|
      image_name = ur.attributes["image"]
      image_path = "#{Rails.root}/public/uploads/upload/recommend/image/#{ur.id}/"
      system "cp #{image_path}#{image_name} #{image_path}large_#{image_name}"
    end
  end

  desc "发完banner裁剪版本后，执行老banner的重新裁剪"
  task :recreate_banners => :environment do
    Upload::Recommend.where(id: Recommend.banners.keys).each do |ur|
      ur.image.recreate_versions!
    end
  end
end