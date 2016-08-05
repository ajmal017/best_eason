namespace :caishuo do
  desc "发送欢迎邮件给种子用户"
  task :send_email_to_seed_user => :environment do
    emails = %W{brave.yuyong@gmail.com
    xiangld77@gmail.com
    lixin10161016@163.com
    xiaouyt@126.com
    441147876@qq.com
    guozan523@gmail.com
    guoluli@caijing.com.cn
    eric.gu@mountlotus.com
    luojian@sinochem.com
    13810019024@139.com
    FuQiang@citicpe.com
    fengliangt@citic.com
    yifei_ren@hotmail.com
    rrrrong@gmail.com
    chenvii@qq.com
    bobby.huang.sauder@gmail.com
    Alex.ma@sbs.ox.ac.uk}
    emails.each do |email|
      puts email
      UserMailer.seed_user_upgrade(email).deliver
    end
  end

  desc "导入新邀请的种子用户"
  task :import_seed_users => :environment do
    emails = %W{
      lzhq2010@163.com
      panhongchuan1987@163.com
      9012lipin@163.com
      mazhangen@hotmail.com
      txtxy1989@163.com
      llm900@hotmail.com
      scwyncmnjb@163.com
      junfeng_feng@ruc.edu.cn
      zhangyunwei@csc.com.cn
      yangshd@fosun.com
      342874272@qq.com
      wuzhenbo@360.cn
      yangeneil@hotmail.com
      cxs-850116@163.com
      au924@163.com
      342948787@qq.com
      543626851@qq.com
      smalone@qq.com
      534902239@qq.com
      172402459@qq.com
      ziqi0086@gmail.com
      346741242@qq.com
      498255427@qq.com
      qianglv@caijing.com.cn
      fuxin@modernmedia.com.cn
      22303519@qq.com
      nathalie316@live.cn
      66887978@qq.com
      sara1984@126.com
      xinyayang@caijing.com.cn
      393492445@qq.com
      xgl6298@sepco1.com
      gloria12345678@163.com
      paddybi@gmail.com
      zaiyong.yang@gmail.com
      chen.liang@yd-bcm.com
      justin.xu@china-sage.com
      daveko381@gmail.com
      haitongwang@yahoo.com
      liuyanc@yahoo.com
      gqliying@gmail.com
      vera.zhao@citi.com
      ken.peng@citi.com
      wangym0124@gmail.com
      cjbzzz@sina.cn
      frankfan1968@hotmail.com
      QianweizuZ@163.com
      309087487@qq.com
      searchergmat@163.com
      qwang624@gmail.com
      backf@163.com
      2250057267@qq.com
      58431002@qq.com
      athena.song@hotmail.com
      Celia.xu@ubs.com
      18611398200@163.com
      meie2004@hotmail.com
      chaoyangfu@gmail.com
      shuo.wang@gmail.com
      shrine2008@163.com.
      sliu@act.is
      David.fang.chen@gmail.com
      420772490@qq.Com
      fangshuai0420@163.com
      Yuanqing@tsinghua.org.cn
      fangrui@sohu-inc.com
      103428758@qq.com
      734174224@qq.com
      xudonghua@vip.126.com
      13824439821@139.com
      346213599@qq.com
      13910858935@163.com
      hp_plasma@hotmail.com
      sh.lan@lacom.com.cn
      Piaoyang@gmail.com
      maxiaofeng@gmail.com
      howtogether@gmail.com
      3188316@qq.com
      jin.jun@nf-technology.com
      haifeng_xu@hotmail.com
      liuweili@linjia.me
      pinhurt@me.com
      niluzhou1984@foxmail.com
      yzqpc@hotmail.com
      strawberry224@163.com
      Smalone@qq.com
      yukiyh@163.com
      xuan.chen@chenheinvest.com
      Zhongmin.pi@cligrp.com
      43807592@QQ.com
      xuebz@ebasset.com
      Longgen.zhang@jessieinternational.com
    }

    emails.each do |email|
      lead = Lead.find_or_create_by(email: email)
      puts lead.id
    end
  end
end
