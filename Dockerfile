FROM ubuntu:22.04 AS builder

ENV NODE_ENV="production"

RUN set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get -qq update \
    && apt-get upgrade -y \
    && apt-get -y --no-install-recommends install \
      apt-transport-https \
      curl gnupg \
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
      libcairo2-dev \
      libpango1.0-dev \
      libjpeg-dev \
      libgif-dev \
      librsvg2-dev \
      gir1.2-rsvg-2.0 \
      librsvg2-2 \
      librsvg2-common \
      libcurl4-openssl-dev \
      libpixman-1-0 lzma lzma-dev \
      libpixman-1-dev; \
    mkdir -p /usr/src/app; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list; \
    apt-get update && apt-get install -y nodejs; \
    curl http://archive.ubuntu.com/ubuntu/pool/main/t/tzdata/tzdata_2019c-3ubuntu1_all.deb --output tzdata_2019c-3ubuntu1_all.deb \
    && curl http://archive.ubuntu.com/ubuntu/pool/main/i/icu/libicu66_66.1-2ubuntu2.1_amd64.deb --output libicu66_66.1-2ubuntu2.1_amd64.deb \
    && apt install ./tzdata_2019c-3ubuntu1_all.deb \
    && apt install ./libicu66_66.1-2ubuntu2.1_amd64.deb \
    && rm -rf ./libicu66_66.1-2ubuntu2.1_amd64.deb \
    && rm -rf ./tzdata_2019c-3ubuntu1_all.deb; \
    apt-get -y --purge autoremove; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*;

WORKDIR /usr/src/app
COPY . .
RUN npm install -g npm && npm install --omit=dev

FROM ubuntu:22.04 AS final

ENV \
    NODE_ENV="production" \
    CHOKIDAR_USEPOLLING=1 \
    CHOKIDAR_INTERVAL=500

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN groupadd --gid 1001 node \
    && useradd --uid 1001 --gid node  --shell /bin/bash --create-home node \
    && set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get -qq update && apt-get upgrade -y; \
    apt-get -y --no-install-recommends install \
      ca-certificates curl gnupg \
      libgles2-mesa \
      libegl1 \
      wget \
      xvfb \
      xauth \
      curl \
      libglfw3 \
      libuv1 \
      libjpeg-turbo8 \
      libcairo2 \
      libgif7 \
      libglfw3 \
      libuv1-dev \
      libc6-dev \
      libcap2-bin \
      libopengl0 \
      libpixman-1-0 \
      libcurl4 \
      librsvg2-2 lzma \
      libpango1.0; \
    update-ca-certificates; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list; \
    apt-get update && apt-get install -y nodejs; \
    npm install -g npm; \
    setcap 'cap_net_bind_service=+ep' /usr/bin/node \
    && curl http://archive.ubuntu.com/ubuntu/pool/main/t/tzdata/tzdata_2019c-3ubuntu1_all.deb --output tzdata_2019c-3ubuntu1_all.deb \
    && curl http://archive.ubuntu.com/ubuntu/pool/main/i/icu/libicu66_66.1-2ubuntu2.1_amd64.deb --output libicu66_66.1-2ubuntu2.1_amd64.deb \
    && apt install ./tzdata_2019c-3ubuntu1_all.deb \
    && apt install ./libicu66_66.1-2ubuntu2.1_amd64.deb \
    && rm -rf ./libicu66_66.1-2ubuntu2.1_amd64.deb \
    && rm -rf ./tzdata_2019c-3ubuntu1_all.deb \
    && apt-get -y remove wget curl; \
    apt-get -y --purge autoremove; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/app /usr/src/app

RUN mkdir -p /data && chown 1001:1001 /data && chown -R 1001:1001 /usr/src/app
VOLUME /data
WORKDIR /data

EXPOSE 8080

USER 1001:1001

ENTRYPOINT ["/usr/src/app/docker-entrypoint.sh"]

HEALTHCHECK CMD node /usr/src/app/src/healthcheck.js