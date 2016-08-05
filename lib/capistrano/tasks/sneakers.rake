namespace :load do
  task :defaults do
    set :sneakers_pid, -> { File.join(shared_path, "pids", "sneakers.pid") }
    set :sneakers_restart_sleep_time, 2
    set :sneakers_roles, -> { :sneakers }
    set :sneakers_options, -> { "WORKERS=Trading::PmsConsumer" }
    set :sneakers_rack_env, -> { fetch(:rails_env) }
    set :sneakers_bundle_gemfile, -> { File.join(current_path, "Gemfile") }
  end
end

namespace :sneakers do
  desc "Start Sneakers"
  task :start do
    on roles(fetch(:sneakers_roles)) do
      within current_path do
        if test("[ -e #{fetch(:sneakers_pid)} ] && kill -0 #{sneakers_pid}")
          info "sneakers is running..."
        else
          with rails_env: fetch(:rails_env), bundle_gemfile: fetch(:sneakers_bundle_gemfile) do
            execute :bundle, "exec rake", "sneakers:run", fetch(:sneakers_options), "RAILS_ENV=#{fetch(:sneakers_rack_env)} PIDFILE=#{fetch(:sneakers_pid)}"
          end
        end
      end
    end
  end

  desc "Stop Sneakers (TERM)"
  task :stop do
    on roles(fetch(:sneakers_roles)) do
      within current_path do
        if test("[ -e #{fetch(:sneakers_pid)} ]")
          if test("kill -0 #{sneakers_pid}")
            info "stopping sneakers..."
            execute :kill, "-s TERM", sneakers_pid
          else
            info "cleaning up dead sneakers pid..."
            execute :rm, fetch(:sneakers_pid)
          end
        else
          info "sneakers is not running..."
        end
      end
    end
  end
  
  
  desc "Immediate Stop Sneakers (QUIT)"
  task :immediate_stop do
    on roles(fetch(:sneakers_roles)) do
      within current_path do
        if test("[ -e #{fetch(:sneakers_pid)} ]")
          if test("kill -0 #{sneakers_pid}")
            info "stopping sneakers..."
            execute :kill, "-s QUIT", sneakers_pid
          else
            info "cleaning up dead sneakers pid..."
            execute :rm, fetch(:sneakers_pid)
          end
        else
          info "sneakers is not running..."
        end
      end
    end
  end
  
  desc "Restart Sneakers (USR1)"
  task :restart do
    on roles(fetch(:sneakers_roles  )) do
      within current_path do
        invoke "sneakers:stop"
        execute :sleep, fetch(:sneakers_restart_sleep_time)
        invoke "sneakers:start"
      end
    end
  end
  
  desc "Gracefully Restart Sneakers (USR1 - stop gracefully and start)"
  task :graceful_restart do
    on roles(fetch(:sneakers_roles)) do
      within current_path do
        if test("[ -e #{fetch(:sneakers_pid)} ] && kill -0 #{sneakers_pid}")
            info "restarting sneakers..."
            execute :kill, "-s USR1", sneakers_pid
            execute :sleep, fetch(:sneakers_restart_sleep_time)
        else
          invoke "sneakers:start"
        end
      end
    end
  end
  
  desc "Immediate Restart Sneakers (HUP - stop immediately and start)"
  task :immediate_restart do
    on roles(fetch(:sneakers_roles)) do
      within current_path do
        if test("[ -e #{fetch(:sneakers_pid)} ] && kill -0 #{sneakers_pid}")
            info "restarting sneakers..."
            execute :kill, "-s HUP", sneakers_pid
            execute :sleep, fetch(:sneakers_restart_sleep_time)
        else
          invoke "sneakers:start"
        end
      end
    end
  end

  desc "Reload Sneakers (USR2)"
  task :reload do
    on roles(fetch(:sneakers_roles)) do
      within current_path do
        if test("[ -e #{fetch(:sneakers_pid)} ] && kill -0 #{sneakers_pid}")
          info "reloading..."
          execute :kill, "-s USR2", sneakers_pid
        else
          invoke "sneakers:start"
        end
      end
    end
  end

  desc "scale up worker (USR2)"
  task :scale_up do
    on roles(fetch(:sneakers_roles)) do
      within current_path do
        info "scaling up worker"
        execute :kill, "-s USR2", sneakers_pid
      end
    end
  end

  desc "scaling down worker (USR2 + USR1)"
  task :scale_down do
    on roles(fetch(:sneakers_roles)) do
      within current_path do
        info "scaling down worker"
        execute :kill, "-s USR2", sneakers_pid
        execute :sleep, fetch(:sneakers_restart_sleep_time)
        execute :kill, "-s USR1", sneakers_pid
      end
    end
  end
end

def sneakers_pid
  "`cat #{fetch(:sneakers_pid)}`"
end
