FROM hub.caishuo.com/ruby:2.2
RUN mkdir /myapp
WORKDIR /myapp
ADD Gemfile /myapp/Gemfile
ADD Gemfile.lock /myapp/Gemfile.lock
RUN gem install bundler --no-rdoc --no-ri
RUN bundle install