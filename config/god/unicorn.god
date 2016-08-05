# sudo gem install god
# run with:  [RAILS_ROOT=/caishuo/web/current] [RAILS_ENV=production] god -c /caishuo/web/current/config/god/global.god
# [RAILS_ROOT=/caishuo/web/current] [RAILS_ENV=production] god load xx.god

God.pid_file_directory ||= '/caishuo/web/shared/pids'

RAILS_ROOT = ENV['RAILS_ROOT'] || '/caishuo/web/current'
RAILS_ENV  = ENV['RAILS_ENV'] || 'production'

# God.log_file = "#{RAILS_ROOT}/log/god.log"
# God.log_level = :info
 
# http://unicorn.bogomips.org/SIGNALS.html

WORKERS_COUNT = (RAILS_ENV == 'production' ? 4 : 8)

WORKERS_COUNT.each do |id|
  God.watch do |w|
    w.group = 'web'
    w.name = 'unicorn'
    w.uid, w.gid = 'www-data', 'www-data'

    w.interval = 30.seconds # default
    w.pid_file = "#{God.pid_file_directory}/god.pid"

    w.env = {'PIDFILE' => w.pid_file, 'RAILS_ENV' => RAILS_ENV}

    # unicorn needs to be run from the rails root
    w.start = "cd #{RAILS_ROOT} && bundle exec unicorn_rails -c #{RAILS_ROOT}/config/unicorn.rb -E #{RAILS_ENV} -D"

    # QUIT gracefully shuts down workers
    w.stop = "kill -QUIT `cat #{God.pid_file_directory}/unicorn.pid`"

    # USR2 causes the master to re-create itself and spawn a new worker pool
    w.restart = "kill -USR2 `cat #{God.pid_file_directory}/unicorn.pid`"

    w.start_grace = 20.seconds
    w.restart_grace = 20.seconds
    
    w.behavior(:clean_pid_file)

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 5.seconds
        c.running = false
      end
    end

    w.restart_if do |restart|
      restart.condition(:memory_usage) do |c|
        c.above = 300.megabytes
        c.times = [3, 5] # 3 out of 5 intervals
      end

      restart.condition(:cpu_usage) do |c|
        c.above = 50.percent
        c.times = 5
      end
    end

    # lifecycle
    w.lifecycle do |on|
      on.condition(:flapping) do |c|
        c.to_state = [:start, :restart]
        c.times = 5
        c.within = 5.minute
        c.transition = :unmonitored
        c.retry_in = 10.minutes
        c.retry_times = 5
        c.retry_within = 2.hours
      end
    end
  end
end