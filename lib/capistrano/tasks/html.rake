namespace :load do
  task :defaults do
    set :html_deploy_to, "#{fetch(:deploy_to)}/html"
    set :html_revision_log, -> { File.join(current_path, "html_revision_log.txt") }
    set :html_linked_dirs,  %w{images javascripts stylesheets fonts zt mobile mzt}
  end
end

namespace :html do

  task :setup do
    on release_roles :web do
      within fetch(:deploy_to) do
        strategy.html_clone
      end
    end
  end


  task :update do
    on release_roles :web do
      if test("[ -e #{fetch(:html_deploy_to)}/.git ]")
        execute "cd #{fetch(:html_deploy_to)} && git checkout #{fetch(:html_branch)} && git pull" 
      else
        invoke 'html:setup' 
      end
      invoke 'html:backup_manifest'
      invoke 'html:links'
    end
  end


  desc '建立软链接 linked_html_dirs'
  task :links do
    next unless any? :html_linked_dirs
    on release_roles :web do
      fetch(:html_linked_dirs).each do |dir|
        target = release_path.join("public", dir)
        # source = "#{fetch(:html_project_path)}/caishuohtml/#{dir}"  # TODO 不起作用
        source = "#{fetch(:html_deploy_to)}/#{dir}"
        execute :ln, '-sfT', source, target
      end
    end
  end


  desc '记录当前静态资源rev, call "git rev-parse"'
  task :backup_manifest do
    on release_roles :web do
      within fetch(:html_deploy_to) do
        if test("[ -f #{fetch(:html_deploy_to)} ]")
          strategy.git :checkout, fetch(:html_branch)
          execute %{cd #{fetch(:html_deploy_to)} && (echo "`git rev-parse --short #{fetch(:html_branch)}`" > #{fetch(:html_revision_log)})}
        end
      end
    end
  end

  desc '回退静态资源'
  task :rollback do
    on release_roles(:web) do
      within fetch(:html_deploy_to) do
        if (target = execute(%{cat #{fetch(:html_revision_log)}}))
          git :checkout, target
        end
      end
    end
  end

end


after "deploy:finishing_rollback", "html:rollback"