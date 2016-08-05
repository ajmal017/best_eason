#!/usr/bin/env ruby

# *** 在 /etc/rc.local 中加入下列命令 ***
# su username -c "BUNDLE_GEMFILE=/caishuo/web/current/Gemfile ruby /path/to/project/server/scripts/resque.rb development|production... worker|scheduler &"
# 加入BUNDLE_GEMFILE=/caishuo/web/current/Gemfile，保证每次启动rake时都调用最新current目录下的Gemfile

# 如果是kill指令，则执行后直接退出
if $*.first == 'kill'
  # 杀掉已在运行的resque:work和resque:scheduler进程
  `ps -eo pid,command | grep resque`.split("\n").map do |line|
    params = line.split(' ')
    if params[1] =~ /^resque-.+:/ || params[1] =~ /^resque-scheduler-.+:$/
      Process.kill($*[1] == '9' ? 'KILL' : 'QUIT', params[0].to_i) rescue nil
    end
  end

  exit
end
