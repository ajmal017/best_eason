
God.pid_file_directory ||= '/caishuo/web/shared/pids'

RAILS_ROOT = ENV['RAILS_ROOT'] || '/caishuo/web/current'
RAILS_ENV  = ENV['RAILS_ENV'] || 'production'

God.log_file = "#{RAILS_ROOT}/log/god.log"
God.log_level = :info


God::Contacts::Email.defaults do |d|
  d.from_email = 'system01@caishuo.com'
  d.from_name = 'God Watcher'
  d.delivery_method = :sendmail
end

God.contact(:email) do |c|
  c.name = 'wangchangming'
  c.group = 'developers'
  c.to_email = 'wangchangming@caishuo.com'
end


