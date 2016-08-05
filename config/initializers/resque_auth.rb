Resque::Server.use(Rack::Auth::Basic) do |user, password|
  user == Setting.resque_auth.username && password == Setting.resque_auth.password
end if Rails.env.production? or Rails.env.staging?


