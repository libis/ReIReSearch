FROM jruby:9.2.9

RUN apt-get update && apt-get -y install cron

# Install gems
ENV APP /app
ENV APP_HOME /app/src
ENV HOME /root

RUN mkdir $APP
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY Gemfile ./
RUN gem install bundler
RUN bundle install