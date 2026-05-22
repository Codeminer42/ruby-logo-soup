# Development image for LogoSoup.
# Provides Ruby + libvips + librsvg so contributors can run specs and develop
# without installing system dependencies locally.
#
# Build:  docker build -t logosoup-dev .
# Test:   docker run --rm -v "$PWD":/app logosoup-dev bundle exec rspec
# Shell:  docker run --rm -it -v "$PWD":/app logosoup-dev

FROM ruby:3.3-slim

ENV DEBIAN_FRONTEND=noninteractive \
    BUNDLE_PATH=/usr/local/bundle

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        libvips42 \
        libvips-dev \
        librsvg2-2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Bake gem dependencies into the image. BUNDLE_PATH lives outside /app, so
# they survive when the working tree is bind-mounted over /app at runtime.
# version.rb is required because the gemspec loads it during install.
COPY Gemfile Gemfile.lock logosoup.gemspec ./
COPY lib/logosoup/version.rb ./lib/logosoup/version.rb

RUN bundle install

CMD ["bash"]
