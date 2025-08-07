FROM ruby:2.7

# Install required packages (updated for newer Debian)
RUN apt-get update && apt-get install -y \
    libmariadb-dev-compat \
    libmariadb-dev \
    libpq-dev \
    libsqlite3-dev \
    nodejs \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# Install specific bundler version that works with Ruby 2.7
RUN gem install bundler:1.17.3

WORKDIR /app
COPY . /app

# Use the fixed Gemfile with https
RUN cp config/database.yml.sample config/database.yml

# Install gems
RUN bundle install --jobs 4 --retry 3 --without production development

CMD ["/bin/bash"]