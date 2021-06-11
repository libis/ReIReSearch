FROM ruby:2.4.3

# Install gems
ENV APP_HOME /app
ENV HOME /root

RUN cp /usr/share/zoneinfo/CET /etc/localtime 
RUN apt-get update
RUN apt-get install -y sgrep
RUN apt-get install -y mdbtools 

RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY Gemfile ./
RUN gem install bundler
RUN bundle install