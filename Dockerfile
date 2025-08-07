# Use Ruby 2.7 as base image (matching the current supported versions)
FROM ruby:2.7-slim

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y \
      build-essential \
      libpq-dev \
      libmysqlclient-dev \
      libsqlite3-dev \
      nodejs \
      git \
      curl \
      tzdata && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock first to leverage Docker cache
COPY Gemfile Gemfile.lock ./

# Install bundler and gems
RUN gem install bundler:1.17.3
RUN bundle install --jobs $(nproc)

# Copy the rest of the application
COPY . .

# Copy entrypoint script
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

# Expose port 3000
EXPOSE 3000

# Use entrypoint script
ENTRYPOINT ["entrypoint.sh"]

# Default command
CMD ["rails", "server", "-b", "0.0.0.0"]