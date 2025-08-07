# Sanataro - Ruby on Rails Household Accounting Application

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Critical Compatibility Information

**CRITICAL**: This application uses very old technology stack that has compatibility issues with modern environments:
- Ruby on Rails 4.2.x (released 2014)
- Bundler 1.17.x (incompatible with Ruby 3.x)
- Ruby 2.5.x to 2.7.x is required for proper functionality

**COMPATIBILITY LIMITATIONS**:
- Ruby 3.x: **DOES NOT WORK** - Rails 4.2.x is incompatible with Ruby 3.x due to BigDecimal API changes
- Modern Bundler (2.x+): **CAUSES ISSUES** - Use bundler 1.17.3 for compatibility
- HAML-lint: **FAILS** with Ruby 3.x due to Rails compatibility issues
- Many modern gems: **INCOMPATIBLE** with Rails 4.2.x

## Working Environment Setup

### Option 1: Docker Approach (Recommended)
Create a Dockerfile for consistent environment:
```dockerfile
FROM ruby:2.7

RUN apt-get update && apt-get install -y \
    libmariadb-dev \
    libpq-dev \
    libsqlite3-dev \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN gem install bundler:1.17.3

WORKDIR /app
COPY . /app
RUN cp config/database.yml.sample config/database.yml
RUN bundle install --jobs 4 --retry 3 --without production development
```

Build and run: `docker build -t sanataro . && docker run -it sanataro bash`

### Option 2: System Ruby Setup (Limited Functionality)
**WARNING**: Many features will not work with modern Ruby versions.

1. **Fix Gemfile source**: Change `source 'http://rubygems.org'` to `source 'https://rubygems.org'`
2. **Install dependencies manually**:
   ```bash
   sudo gem install rails:4.2.11
   sudo gem install sqlite3:1.3.11
   sudo gem install rubocop
   ```

## Bootstrap Commands

### Database Setup
```bash
cp config/database.yml.sample config/database.yml
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:seed  # Creates demo user (username: demo, password: demo123)
```

**Timing**: Database operations take 10-30 seconds. NEVER CANCEL these operations.

### Development Server
```bash
bundle exec rails server
# OR
bundle exec rails s
```
**Access**: http://localhost:3000
**Demo User**: username=demo, password=demo123

## Linting and Quality Checks

### RuboCop (Code Style)
```bash
bundle exec rubocop .
```
**Timing**: Takes 5-10 seconds. Expected to find style violations.
**Note**: Modern RuboCop may show many "new cops" warnings - this is normal.

### HAML-lint (Template Style)
```bash
bundle exec haml-lint .
```
**CRITICAL**: This command **FAILS** with Ruby 3.x due to Rails compatibility issues.
**Workaround**: Use Docker with Ruby 2.7 or skip HAML linting in modern environments.

## Testing

### RSpec Tests
```bash
bundle exec rake spec
```
**Timing**: Takes 60-120 seconds. NEVER CANCEL. Set timeout to 180+ seconds.

### Cucumber Integration Tests
```bash
# Requires xvfb for headless browser testing
xvfb-run --auto-servernum bundle exec rake cucumber
```
**Timing**: Takes 120-300 seconds. NEVER CANCEL. Set timeout to 600+ seconds.
**Dependencies**: Requires capybara-webkit, xvfb, libqtwebkit packages

### Run All Tests (CI Mode)
```bash
bundle exec rake travis
```

## Validation Scenarios

**ALWAYS** test these scenarios after making changes:

1. **User Registration and Login**:
   - Visit http://localhost:3000
   - Create a new user account
   - Log in successfully

2. **Basic Accounting Entry**:
   - Add a new income entry
   - Add a new expense entry
   - Verify entries appear in the list

3. **Account Management**:
   - Create a new account (bank account, wallet, etc.)
   - Transfer money between accounts
   - Check balance calculations

## Common Build Issues and Solutions

### Bundle Install Failures
**Problem**: `bundle install` fails with Ruby 3.x
**Solution**: Use Docker with Ruby 2.7 or install gems manually

### BigDecimal Errors
**Problem**: `undefined method 'new' for BigDecimal:Class`
**Solution**: Use Ruby 2.7 or earlier. Rails 4.2.x is not compatible with Ruby 3.x

### HAML-lint Failures
**Problem**: HAML-lint crashes with Rails loading errors
**Solution**: Use Docker environment or skip HAML linting

### Qt WebKit Dependency Issues
**Problem**: capybara-webkit fails to install
**Solution**: Install system packages: `libqtwebkit-dev libqtwebkit4` (Debian/Ubuntu)

## CI/CD Information

### GitHub Actions Workflow
Path: `.github/workflows/ruby.yml`
- Uses Ruby 2.5.x
- Installs system dependencies
- Runs RuboCop, HAML-lint, RSpec, and Cucumber
- Requires xvfb for headless browser testing

### Travis CI (Legacy)
Path: `.travis.yml`
- Supports multiple Ruby versions and databases
- Matrix builds for different configurations

## Repository Structure

### Key Directories
- `app/models/` - ActiveRecord models (User, Item, Account, etc.)
- `app/controllers/` - Rails controllers (entries, settings, API)
- `app/views/` - HAML templates
- `spec/` - RSpec unit tests
- `features/` - Cucumber integration tests
- `config/` - Rails configuration files

### Important Files
- `Gemfile` - Gem dependencies (MUST use https://rubygems.org)
- `config/database.yml.sample` - Database configuration template
- `config/application.yml` - Application settings
- `.rubocop.yml` - Code style configuration
- `.haml-lint.yml` - Template style configuration

### Key Models
- `User` - Application users with login/password
- `Item` - Base class for accounting entries
- `GeneralItem`, `Income`, `Expense` - Specific entry types
- `Account` - Bank accounts, wallets, credit cards
- `MonthlyProfitLoss` - Monthly financial summaries

## Common Commands Reference

```bash
# Environment setup
cp config/database.yml.sample config/database.yml
bundle install

# Database operations
bundle exec rake db:create          # 10-30 seconds
bundle exec rake db:migrate         # 10-30 seconds  
bundle exec rake db:seed            # 10-30 seconds

# Development
bundle exec rails server            # Start dev server
bundle exec rails console           # Rails console

# Testing - NEVER CANCEL
bundle exec rake spec               # 60-120 seconds
bundle exec rake cucumber           # 120-300 seconds

# Linting
bundle exec rubocop .               # 5-10 seconds
bundle exec haml-lint .             # FAILS with Ruby 3.x

# Build assets
bundle exec rake assets:precompile  # 30-60 seconds
```

## Known Working Ruby/Environment Versions

- **Ruby 2.5.x**: ✅ Fully supported (used in CI)
- **Ruby 2.6.x**: ✅ Supported
- **Ruby 2.7.x**: ✅ Supported (recommended for Docker)
- **Ruby 3.x**: ❌ **NOT SUPPORTED** - Rails 4.2.x incompatible

## Demo Access

After running `rake db:seed`:
- **URL**: http://localhost:3000
- **Username**: demo
- **Password**: demo123
- **Admin URL**: http://localhost:3000/admin/users
- **Admin Credentials**: admin/password (development)

## Troubleshooting

### Build Failures
1. Check Ruby version compatibility
2. Verify Gemfile uses https://rubygems.org
3. Use Docker for consistent environment
4. Install system dependencies for testing

### Test Failures
1. Ensure database is migrated and seeded
2. Install xvfb for headless browser tests
3. Check Qt WebKit dependencies for Capybara

### Modern Environment Issues
1. Use Docker with Ruby 2.7 for full compatibility
2. Skip HAML-lint if using Ruby 3.x
3. Install gems manually if bundler fails