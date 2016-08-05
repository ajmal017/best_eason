# sudo gem install god
# run with:  [RAILS_ROOT=/caishuo/web/current] [RAILS_ENV=staging] god -c /caishuo/web/current/config/god/scheduler.god

pid_file_directory ||= '/caishuo/web/shared/pids'

RAILS_ROOT = ENV['RAILS_ROOT'] || '/caishuo/web/current'
RAILS_ENV  = ENV['RAILS_ENV'] || 'staging'
workers = "Trading::PmsConsumer,FeedConsumer,StockRealtimeConsumer"

God.watch do |w|
  w.group = 'mq'
  w.name = 'sneakers'
  w.uid, w.gid = 'caishuo', 'caishuo'
  
  w.dir = RAILS_ROOT
  w.log = "#{RAILS_ROOT}/log/sneakers.log"
  w.pid_file = "#{pid_file_directory}/sneakers.pid"
  w.env = {'WORKERS'=>workers, 'PIDFILE' => w.pid_file, 'RAILS_ENV' => RAILS_ENV}
  
  w.interval = 30.seconds
  w.grace = 5.seconds
  
  w.start = "bundle exec rake sneakers:run"
  w.restart = "kill -9 `cat #{w.pid_file}`"

  w.behavior(:clean_pid_file)
   # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end
  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
      c.interval = 5.seconds
    end
    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
      c.interval = 5.seconds
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_running) do |c|
      c.running = false
    end
  end

end
