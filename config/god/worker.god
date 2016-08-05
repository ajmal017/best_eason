# sudo gem install god
# run with:  [RAILS_ROOT=/caishuo/web/current] [RAILS_ENV=production] god -c /caishuo/web/current/config/god/worker.god

God.pid_file_directory ||= '/caishuo/web/shared/pids'

RAILS_ROOT = ENV['RAILS_ROOT'] || '/caishuo/web/current'
RAILS_ENV  = ENV['RAILS_ENV'] || 'production'

QUEUES = {
  data_default: 4,
  order: 2,
  default: 4
}.map{|k, v| Array.new(v, k)}.flatten

MAX_COUNT = QUEUES.length

(1..MAX_COUNT).each do |id|
  God.watch do |w|
    w.group = 'resque'
    w.name = "worker.#{id}"
    w.uid, w.gid = 'www-data', 'www-data'
    
    w.dir = RAILS_ROOT
    w.log = "#{RAILS_ROOT}/log/worker.log"
    w.pid_file = "#{God.pid_file_directory}/worker.#{id}.pid"
    # queue_name = (id <= NON_MAIL_COUNT ? '*,!mail_*' : 'mail_*')
    # queue_name = ::YAML.load_file("#{RAILS_ROOT}/config/resque.yml").fetch('queues').join(',')
    queue_name = "@#{QUEUES[id-1]}"
    w.env = {'PIDFILE' => w.pid_file, 'RAILS_ENV' => RAILS_ENV, 'QUEUE' => queue_name, 'TERM_CHILD' => id, "RESQUE_TERM_TIMEOUT"=>10}
    w.interval = 5.seconds
    w.grace = 120.seconds

    w.start = "bundle exec rake resque:work --trace &"
    
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
      on.condition(:memory_usage) do |c|
        c.above = 350.megabytes
        c.times = 2
      end
    end

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