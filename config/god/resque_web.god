# sudo gem install god
# run with:  [RAILS_ROOT=/caishuo/web/current] [RAILS_ENV=production] god -c /caishuo/web/current/config/god/resque_web.god

God.pid_file_directory ||= '/caishuo/web/shared/pids'

RAILS_ROOT = ENV['RAILS_ROOT'] || '/caishuo/web/current'
RAILS_ENV  = ENV['RAILS_ENV'] || 'production'

God.watch do |w|
  w.group = 'resque_web'
  w.name = 'ui'
  w.uid, w.gid = 'www-data', 'www-data'
  
  w.dir = RAILS_ROOT
  w.log = "#{RAILS_ROOT}/log/resque_web.log"
  w.pid_file = "#{God.pid_file_directory}/resque_web.pid"
  w.env = {'RAILS_ENV' => RAILS_ENV, 'RAILS_ROOT' => RAILS_ROOT}
  
  w.interval = 20.seconds
  w.grace = 5.seconds
  
  w.start = "cd #{RAILS_ROOT} && bundle exec resque-web config/resque_web.rb"
  w.restart = "bundle exec resque-web -K"

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
