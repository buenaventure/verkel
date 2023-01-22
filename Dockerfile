# syntax=docker/dockerfile:1
FROM ruby:3.1.3-alpine as builder

# full system dependencies
RUN apk --update --no-cache add \
    build-base \
    gcc \
    make \
    postgresql-client \
    postgresql-dev \
    tzdata \
    yarn \
    && rm -rf /var/cache/apk/*

# bundle
WORKDIR /verkel
COPY Gemfile ./Gemfile
COPY Gemfile.lock ./Gemfile.lock
RUN bundle config set --local without 'development test'
RUN bundle config set --local deployment 'true'
RUN bundle install --jobs 20 --retry 5

# yarn
COPY package.json yarn.lock ./
RUN yarn install --check-files

# app & assets
COPY . ./
RUN RAILS_ENV=production SECRET_KEY_BASE=0 bundle exec rails assets:precompile
RUN rm -rf node_modules
RUN rm -rf tmp/* && mkdir tmp/pids
RUN rm -rf vendor/bundle/ruby/3.1.0/cache


FROM ruby:3.1.3-alpine

# system dependencies without stuff needed to build native extensions
RUN apk --update --no-cache add \
    postgresql-client \
    tzdata \
    && rm -rf /var/cache/apk/*

WORKDIR /verkel
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=1

COPY --from=builder /verkel /verkel
RUN bundle config --local path vendor/bundle
RUN bundle config --local without development:test:assets

# update system for security
RUN apk --update --no-cache upgrade && rm -rf /var/cache/apk/*

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]