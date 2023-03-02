ARG BASE_IMAGE=ruby:2.7.6-slim-bullseye
ARG CACHE_IMAGE=${BASE_IMAGE}

# Build stage for the gem cache
FROM ${CACHE_IMAGE} AS gem-cache
RUN mkdir -p /usr/local/bundle

### Base image with Bundler Installed ###
FROM $BASE_IMAGE AS base

# Allow for setting ENV vars via --build-arg
ARG BUNDLE_ENTERPRISE__CONTRIBSYS__COM \
  RAILS_ENV=development \
  USER_ID=1000
ENV RAILS_ENV=$RAILS_ENV \
  BUNDLE_ENTERPRISE__CONTRIBSYS__COM=$BUNDLE_ENTERPRISE__CONTRIBSYS__COM \
  BUNDLER_VERSION=2.1.4 \
  LANG=C.UTF-8

RUN gem install bundler:${BUNDLER_VERSION} --no-document
WORKDIR /usr/src/app

# Create nonroot user and workdir
RUN groupadd --gid $USER_ID nonroot \
  && useradd --uid $USER_ID --gid nonroot --shell /bin/bash --create-home nonroot --home-dir /app
WORKDIR /app

# Install system packages
RUN echo "deb http://ftp.debian.org/debian testing main contrib non-free" >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y -t testing poppler-utils
RUN apt-get install -y build-essential libpq-dev git imagemagick curl wget pdftk file

# Relax ImageMagick PDF security. See https://stackoverflow.com/a/59193253.
RUN sed -i '/rights="none" pattern="PDF"/d' /etc/ImageMagick-6/policy.xml

# Install fwdproxy.crt into trust store
# Relies on update-ca-certificates being run in following step
COPY config/ca-trust/*.crt /usr/local/share/ca-certificates/

# Download VA Certs
COPY ./import-va-certs.sh .
RUN ./import-va-certs.sh

# Copy clamav config into system config
COPY config/clamd.conf /etc/clamav/clamd.conf

### Install gems from gem-cache build stage ###
FROM base AS gems

# Install gems using cache
COPY --from=gem-cache /usr/local/bundle /usr/local/bundle
COPY modules ./modules
COPY Gemfile Gemfile.lock ./
RUN bundle install

### Main stage for development and deployed environments ###
FROM base AS app

COPY --chown=nonroot:nonroot --from=gems /usr/local/bundle /usr/local/bundle
COPY --chown=nonroot:nonroot . .

EXPOSE 3000

USER nonroot

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
