FROM ubuntu:focal AS builder

ENV NODE_ENV="production"

RUN set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get -qq update \
    && apt-get upgrade -y \
    && apt-get -y --no-install-recommends install \
      apt-transport-https \
      curl \
      unzip \
      build-essential \
      ca-certificates \
      wget \
      pkg-config \
      xvfb \
      python3 \
      libgles2-mesa-dev \
      libgbm-dev \
      libprotobuf-dev \
      libglfw3-dev \
      libuv1-dev \
      libjpeg-turbo8 \
      libicu66 \
      libcairo2-dev \
      libpango1.0-dev \
      libjpeg-dev \
      libgif-dev \
      librsvg2-dev \
      libcurl4-openssl-dev \
      libpixman-1-dev; \
    wget -qO- https://deb.nodesource.com/setup_16.x | bash; \
    apt-get install -y nodejs; \
    apt-get -y remove wget; \
    apt-get -y --purge autoremove; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*;

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY . .
RUN npm install -g npm && npm ci --omit=dev

FROM ubuntu:focal AS final

ENV \
    NODE_ENV="production" \
    CHOKIDAR_USEPOLLING=1 \
    CHOKIDAR_INTERVAL=500
RUN groupadd --gid 1001 node \
    && useradd --uid 1001 --gid node  --shell /bin/bash --create-home node \
    && set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    groupadd -r node; \
    useradd -r -g node node; \
    apt-get -qq update && apt-get upgrade -y \
    apt-get -y --no-install-recommends install \
      ca-certificates \
      libgles2-mesa \
      libegl1 \
      wget \
      xvfb \
      xauth \
      curl \
      libglfw3 \
      libuv1 \
      libjpeg-turbo8 \
      libicu66 \
      libcairo2 \
      libgif7 \
      libglfw3 \
      libuv1-dev \
      libc6-dev \
      libcap2-bin \
      libopengl0 \
      libpixman-1-0 \
      libcurl4 \
      librsvg2-2 \
      libpango1.0 \
    && update-ca-certificates \
    && wget -qO- https://deb.nodesource.com/setup_16.x | bash; \
    apt-get install -y nodejs; \
    apt-get -y remove wget; \
    apt-get -y --purge autoremove; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* \
    && npm install -g npm

COPY --from=builder /usr/src/app /usr/src/app

RUN mkdir -p /data && chown 1001:1001 /data && chown -R 1001:1001 /usr/src/app
VOLUME /data
WORKDIR /data

EXPOSE 8080

USER 1001:1001

ENTRYPOINT ["/usr/src/app/docker-entrypoint.sh"]

HEALTHCHECK CMD node /usr/src/app/src/healthcheck.js
