require 'simplecov'
SimpleCov.profiles.define 'caishuo' do
  load_profile 'rails'
  add_filter '/spec/'
  add_filter '/config/'
  # add_filter '/lib/'
  add_filter '/vendor/'

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Helpers', 'app/helpers'
  add_group 'Mailers', 'app/mailers'
  add_group 'Views', 'app/views'
  add_group 'Workers', 'app/workers'
  add_group 'Workers', 'app/trading'
end