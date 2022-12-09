FROM ubuntu:22.04 AS builder
WORKDIR /tmp
RUN groupadd --gid 1001 node \
  && useradd --uid 1001 --gid node  --shell /bin/bash --create-home node
COPY setup_16x.sh .
RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get -qq update \
  && apt-get upgrade -y \
  && apt-get -y --no-install-recommends install \
      apt-transport-https \
      curl \
      unzip \
      build-essential \
      python3 \
      libcairo2-dev \
      libgles2-mesa-dev \
      libgbm-dev \
      libprotobuf-dev \
      ca-certificates \
  && ./setup_16x.sh \
  && apt-get install -y nodejs \
  && apt-get -y --purge autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY . .

ENV NODE_ENV="production"

RUN npm install -g npm && npm install --omit=dev	
	


FROM ubuntu:22.04 AS final
WORKDIR /tmp
COPY setup_16x.sh .
RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get -qq update \
  && apt-get upgrade -y \
  && apt-get -y --no-install-recommends install \
      libgles2-mesa \
      libegl1 \
      xvfb \
      xauth \
      libopengl0 \
      libcurl4 \
      curl \
      libcairo2 libgif7 libglfw3 libpixman-1-0 librsvg2-2 libpango1.0 \
      libuv1-dev \
      libc6-dev \
      libcap2-bin \
      libjpeg-turbo8 \
      ca-certificates \
  && update-ca-certificates \
  && ./setup_16x.sh \
  && apt-get install -y nodejs \
  && apt-get -y --purge autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && setcap 'cap_net_bind_service=+ep' /usr/bin/node \
  && curl http://archive.ubuntu.com/ubuntu/pool/main/t/tzdata/tzdata_2019c-3ubuntu1_all.deb --output tzdata_2019c-3ubuntu1_all.deb \
  && curl http://archive.ubuntu.com/ubuntu/pool/main/i/icu/libicu66_66.1-2ubuntu2.1_amd64.deb --output libicu66_66.1-2ubuntu2.1_amd64.deb \
  && apt install ./tzdata_2019c-3ubuntu1_all.deb \
  && apt install ./libicu66_66.1-2ubuntu2.1_amd64.deb \
  && rm -rf ./libicu66_66.1-2ubuntu2.1_amd64.deb \
  && rm -rf ./tzdata_2019c-3ubuntu1_all.deb \
  && npm install -g npm

WORKDIR /app
COPY --from=builder /usr/src/app /app

ENV NODE_ENV="production"
ENV CHOKIDAR_USEPOLLING=1
ENV CHOKIDAR_INTERVAL=500

VOLUME /data
WORKDIR /data

# allow node to listen on low ports
EXPOSE 8080

USER 1001:1001

ENTRYPOINT ["/app/docker-entrypoint.sh"]
