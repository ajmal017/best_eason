require 'capistrano/scm'
require 'capistrano/console'
require File.expand_path('../../lib/capistrano/extention', __FILE__)

lock '3.2.1'

set :application, 'caishuo'

set :repo_url, 'ssh://git@gitlab.caishuo.com:10022/ruby/caishuo.git'
set :repo_html_url, 'ssh://git@gitlab.caishuo.com:10022/frontend/html.git'

set :deploy_to, "/caishuo/web"
set :html_deploy_to, "#{fetch(:deploy_to)}/html"
set :deploy_via, :remote_cache
set :bundle_flags, '--no-deployment -V'

set :linked_files, fetch(:linked_files, []).push("config/database.yml", "config/mongoid.yml", "config/publisher.yml", "config/initializers/secret_token.rb", "config/redis.yml", "config/ca_certificate.pem", "config/client_certificate.pem", "config/client_key.pem", ".ruby-version", "config/newrelic.yml", "config/p2p_client.yml")
set :linked_dirs, fetch(:linked_dirs, []).push("bin", "log", "tmp/pids", "tmp/cache", "tmp/sockets", "vendor/bundle", "public/uploads", "public/caches")

set :puma_conf, "#{deploy_to}/current/config/puma.rb"
set :puma_role, :web

set :keep_releases, 5

namespace :bluepill do
  # 确认问题：
  #  创建 /var/execute/bluepill被创建并属于www用户？
  task :prepare do
    on release_roles :web do
      set :user, 'caishuoAdmin'
      default_execute_options[:pty] = true # for remote interaction
      sudo "mkdir -p /var/execute/bluepill"
      sudo "chown www-data:www-data /var/execute/bluepill"
      puts "Prepare bluepill to monitor unicorn... "
    end
  end

  task :start do
    on release_roles :web do
      execute "cd #{current_path} && RAILS_ENV=#{fetch(:rails_env)} bundle exec bluepill --no-privileged load #{current_path}/config/bluepill.rb"
    end
  end

  task :stop do
    on roles(fetch(:unicorn_roles)) do
      within current_path do
        execute "cd #{current_path} && bundle exec bluepill --no-privileged quit"
      end
    end
  end
end

namespace :deploy do
  desc 'tmp shell'
  task :tmp_shell do
    on roles(fetch(:app)) do
      # within current_path do
        # execute "rm -rf /caishuo/web/repo"
        execute "mkdir -p /caishuo/share/caishuocom/public"
        execute "ln -s /caishuo/share/caishuocom/public/market  /caishuo/web/shared/public/market"
      # end
    end
  end

  task :upload do
    on release_roles :app do |host|
      upload! 'config/p2p_client.yml.example', "#{fetch(:deploy_to)}/shared/config/p2p_client.yml"
    end
  end


  task :upload_newrelic do
    on release_roles :app do |host|
      upload! 'config/newrelic.yml.example', "#{fetch(:deploy_to)}/shared/config/newrelic.yml"
    end
  end
  
  
  # 重启服务
  task :start do
    # on roles(fetch(:unicorn_roles)) do
    #   within current_path do
    #     execute "cd #{current_path} && bundle exec bluepill --no-privileged start unicorn RAILS_ENV=#{fetch(:rails_env)}"
    #   end
    # end
  end

  task :stop do
    # on roles(fetch(:unicorn_roles)) do
    #   within current_path do
    #     execute "cd #{current_path} && bundle exec bluepill --no-privileged stop unicorn RAILS_ENV=#{fetch(:rails_env)}"
    #   end
    # end
  end
  task :restart do
    # on roles(fetch(:unicorn_roles)) do
    #   if fetch(:rails_env) == 'production'
    #     execute "cd #{current_path} && bundle exec bluepill --no-privileged restart unicorn RAILS_ENV=#{fetch(:rails_env)}"
    #   else
    #     invoke 'unicorn:restart'
    #   end
    # end
  end
  
  task :restart_unicorn do
    on roles(fetch(:unicorn_roles)) do
      if fetch(:rails_env) == 'production'
        execute "cd #{current_path} && bundle exec bluepill --no-privileged restart unicorn RAILS_ENV=#{fetch(:rails_env)}"
      else
        invoke 'unicorn:restart'
      end
    end
  end

  task :stop_unicorn do
    on roles(fetch(:unicorn_roles)) do
      if fetch(:rails_env) == 'production'
        execute "cd #{current_path} && bundle exec bluepill --no-privileged restart unicorn RAILS_ENV=#{fetch(:rails_env)}"
      else
        invoke 'unicorn:stop'
      end
    end
  end


  after :restart, :bg do
    invoke 'resque:stop'
    invoke 'resque:scheduler:stop'
  end

end


after 'deploy:updating', 'html:update'
after 'deploy:publishing', 'deploy:restart'
after 'deploy:restart', 'sneakers:stop'
