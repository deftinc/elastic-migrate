FROM node:10-slim as base

# Install jq and curl
RUN apt-get update -q && apt-get install -qy curl jq

# Install bats for testing
ENV BATS_HOME=/home/bats
RUN mkdir -p $BATS_HOME && \
  wget -P $BATS_HOME https://github.com/bats-core/bats-core/archive/v1.1.0.tar.gz && \
  tar -xf $BATS_HOME/v1.1.0.tar.gz -C $BATS_HOME && \
  $BATS_HOME/bats-core-1.1.0/install.sh /usr/local

# Make elastic-migrate a user
RUN useradd --user-group --create-home --shell /bin/false elastic-migrate

# Home is elastic-migrate user, node modules in node_modules
ENV HOME=/home/elastic-migrate
ENV NODE_PATH=/node_modules
ENV PATH=$PATH:./node_modules/.bin

# Own everything in home, switch to elastic-migrate user
RUN mkdir -p $HOME/migrations && \
  chown -R elastic-migrate:elastic-migrate $HOME/*
USER elastic-migrate

# Copy application
WORKDIR $HOME

# Install dev node_modules
COPY --chown=elastic-migrate:elastic-migrate package* ./
RUN npm ci

# Install elastic-migrate binary
COPY --chown=elastic-migrate:elastic-migrate . ./
RUN npm install .

USER root
RUN npm link
USER elastic-migrate

ENTRYPOINT [ "/bin/bash", "./run.sh" ]
CMD [ "migrate-up" ]

# ---

FROM node:10-alpine as deploy

COPY . ./
RUN npm install -g . && npm link
ENTRYPOINT [ "elastic-migrate"]