set :rails_env, 'testing'
set :branch, 'testing'
set :html_branch, 'testing'
set :deploy_to, "/caishuo/web"
set :html_deploy_to, "/caishuo/web/html"

role :app, %w{www-data@192.168.1.11}
role :web, %w{www-data@192.168.1.11}
role :db,  %w{www-data@192.168.1.11}
role :sneakers,  %w{www-data@192.168.1.11}


role :resque_worker, "www-data@192.168.1.11"
role :resque_scheduler, "www-data@192.168.1.11"
