FROM ruby:2.4.3
#RUN apt-get update && \
#    apt-get install -y net-tools

# Install gems
ENV APP_HOME /app
ENV HOME /root

RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY Gemfile* $APP_HOME/
RUN gem install bundler
RUN bundle install
