FROM ubuntu:focal AS builder

ENV NODE_ENV="production"

RUN set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get -qq update; \
    apt-get -y --no-install-recommends install \
      build-essential=12.8ubuntu1 \
      ca-certificates=20211016~20.04.1 \
      wget=1.20.3-1ubuntu1 \
      pkg-config=0.29.1-0ubuntu4 \
      xvfb=2:1.20.13-1ubuntu1~20.04.4 \
      libglfw3-dev=3.3.2-1 \
      libuv1-dev=1.34.2-1ubuntu1.3 \
      libjpeg-turbo8=2.0.3-0ubuntu1.20.04.3 \
      libicu66=66.1-2ubuntu2.1 \
      libcairo2-dev=1.16.0-4ubuntu1 \
      libpango1.0-dev=1.44.7-2ubuntu4 \
      libjpeg-dev=8c-2ubuntu8 \
      libgif-dev=5.1.9-1 \
      librsvg2-dev=2.48.2-1 \
      gir1.2-rsvg-2.0=2.48.2-1 \
      librsvg2-2=2.48.2-1 \
      librsvg2-common=2.48.2-1 \
      libcurl4-openssl-dev=7.68.0-1ubuntu2.14 \
      libpixman-1-dev=0.38.4-0ubuntu1 \
      libpixman-1-0=0.38.4-0ubuntu1; \
      apt-get -y --purge autoremove; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/*;

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN wget -qO- https://deb.nodesource.com/setup_16.x | bash; \
    apt-get install -y nodejs; \
    npm i -g npm@latest; \
    apt-get -y remove wget; \
    apt-get -y --purge autoremove; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*;

RUN mkdir -p /usr/src/app
COPY package* /usr/src/app

WORKDIR /usr/src/app

RUN npm install --omit=dev

FROM ubuntu:focal AS final

ENV \
    NODE_ENV="production" \
    CHOKIDAR_USEPOLLING=1 \
    CHOKIDAR_INTERVAL=500

RUN set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    groupadd -r node; \
    useradd -r -g node node; \
    apt-get -qq update; \
    apt-get -y --no-install-recommends install \
      ca-certificates=20211016~20.04.1 \
      wget=1.20.3-1ubuntu1 \
      xvfb=2:1.20.13-1ubuntu1~20.04.4 \
      libglfw3=3.3.2-1 \
      libuv1=1.34.2-1ubuntu1.3 \
      libjpeg-turbo8=2.0.3-0ubuntu1.20.04.3 \
      libicu66=66.1-2ubuntu2.1 \
      libcairo2=1.16.0-4ubuntu1 \
      libgif7=5.1.9-1 \
      libopengl0=1.3.2-1~ubuntu0.20.04.2 \
      libpixman-1-0=0.38.4-0ubuntu1 \
      libcurl4=7.68.0-1ubuntu2.14 \
      librsvg2-2=2.48.2-1 \
      libpango-1.0-0=1.44.7-2ubuntu4; \
      apt-get -y --purge autoremove; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/*;

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN wget -qO- https://deb.nodesource.com/setup_16.x | bash; \ 
    apt-get install -y nodejs; \
    npm i -g npm@latest; \
    apt-get -y remove wget; \
    apt-get -y --purge autoremove; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*;

COPY --from=builder /usr/src/app /usr/src/app

COPY . /usr/src/app

RUN mkdir -p /data && chown node:node /data
VOLUME /data
WORKDIR /data

EXPOSE 8080

USER node:node

ENTRYPOINT ["/usr/src/app/docker-entrypoint.sh"]

HEALTHCHECK CMD node /usr/src/app/src/healthcheck.js
