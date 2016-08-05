namespace :contests do
  desc "初始化几条数据"
  task :init_contest => :environment do
    datas = [
      {status: Contest.statuses[:finished], name: "A股虚拟大赛", start_at: "2015-05-11", end_at: "2015-05-22"},
      {status: Contest.statuses[:running], name: "A股50强大赛", start_at: "2015-05-25", end_at: "2015-06-17"},
      {status: Contest.statuses[:init], name: "A股实盘大赛"}
    ]
    Contest.create(datas)
  end
end