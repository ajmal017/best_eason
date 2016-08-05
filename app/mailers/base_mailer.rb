# coding: utf-8
class BaseMailer < ActionMailer::Base
  #default :from => 'postmaster@caishuo.sendcloud.org'
  #default :from => (Mail::Encodings.b_value_encode 'from名称 ', 'UTF-8').to_s  + 
  #default :from => '财说科技postmaster@caishuo.sendcloud.org'
  default :from => (Mail::Encodings.b_value_encode '财说', 'UTF-8').to_s  + '<from@sendcloud.com>'
  #default :charset => 'utf-8'
  #default :content_type => 'text/html'

  layout false
  helper :application
end
