FROM ubuntu:focal AS builder

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get -qq update \
  && apt-get -y --no-install-recommends install \
      ca-certificates \
      wget \
  && apt-get -y --purge autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
  
RUN wget -qO- https://deb.nodesource.com/setup_16.x | bash
RUN apt-get install -y nodejs

COPY . /usr/src/app

ENV NODE_ENV="production"

RUN cd /usr/src/app && npm install --production


FROM ubuntu:focal AS final

RUN groupadd -r node && useradd -r -g node node

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get -qq update \
  && apt-get -y --no-install-recommends install \
      ca-certificates \
      wget \
      pkg-config \
      xvfb \
      libglfw3-dev \
      libuv1-dev \
      libjpeg-turbo8 \
      libicu66 \
      unzip \
      libcurl4-openssl-dev \
  && apt-get -y --purge autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN wget -qO- https://deb.nodesource.com/setup_16.x | bash
RUN apt-get install -y nodejs

COPY --from=builder /usr/src/app /app

ENV NODE_ENV="production"
ENV CHOKIDAR_USEPOLLING=1
ENV CHOKIDAR_INTERVAL=500

VOLUME /data
WORKDIR /data

EXPOSE 80

USER node:node

ENTRYPOINT ["/app/docker-entrypoint.sh"]
