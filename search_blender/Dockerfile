#FROM crystallang/crystal:latest as build
#FROM crystallang/crystal:0.28.0-build as build
FROM crystallang/crystal:0.32.1-build as build

# Relavite path do not work in config files !!!! 
#  Do NOT use ./log/search_blender_debug.log
#   but /app/log/search_blender_debug.log

WORKDIR /app

ADD . /src
WORKDIR /src
RUN shards build --production --release

FROM ubuntu:latest
# => Current verion 
# => cat /etc/os-release
# => PRETTY_NAME="Ubuntu 20.04.1 LTS" VERSION_ID="20.04"

#FROM ubuntu:18.04
#RUN apt update
# dropped in Ubuntu 18.04.
#RUN apt-get -y install libssl1.0.0 
#RUN apt-get -y install libevent-2.1.6
#RUN ln -s /usr/lib/x86_64-linux-gnu/libevent-2.1.so.6 /usr/lib/x86_64-linux-gnu/libevent-2.0.so.5
#RUN apt-get -y install ca-cacert
#RUN rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
  libssl1.1 \
  libevent-2.1.7 \
  ca-cacert \
  && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/lib/x86_64-linux-gnu/libevent-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent-2.1.so.6

COPY --from=0 /src/bin/search_blender /search_blender

EXPOSE 3000

ENTRYPOINT ["/search_blender"]