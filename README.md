# Collector

A Rails 8.1 application for managing Magic: The Gathering card collections. Collector integrates with the [MTGJSON](https://mtgjson.com/) SQLite database to provide comprehensive card data as a read-only reference source.

## Features

- **Collection Management**: Organize your cards into collections with nested storage units (boxes, binders, decks)
- **Set Browser**: Browse all MTG sets with filtering by type and pagination
- **Card Search**: Search cards by name or set code with instant results
- **Card Details**: View comprehensive card information including legalities, rulings, and other printings
- **MTGJSON Integration**: Access data for 107K+ cards and 800+ sets

## Requirements

- Ruby 3.4
- SQLite3
- Chrome/Chromium (for system tests)

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/plainprogrammer/collector.git
   cd collector
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up databases**
   ```bash
   bin/rails db:prepare
   ```

4. **Download MTGJSON database** (~500MB)
   ```bash
   bin/rails mtgjson:download
   ```

5. **Start the development server**
   ```bash
   bin/dev
   ```

Visit `http://localhost:3000` to access the application.

## Configuration

### Multi-Database Architecture

Collector uses Rails multi-database support with two separate SQLite databases:

| Database | Purpose | Access |
|----------|---------|--------|
| `primary` | Application data (collections, items) | Read/Write |
| `mtgjson` | Card reference data from MTGJSON | Read-only |

The MTGJSON database is external reference data and is strictly read-only. All writes are prevented at the model level.

### MTGJSON Database Management

```bash
# Download the database (required for development)
bin/rails mtgjson:download

# Update to latest version (creates backup)
bin/rails mtgjson:refresh

# Display database info and statistics
bin/rails mtgjson:info

# Verify database integrity
bin/rails mtgjson:verify

# Clean up old backups (keeps last 3)
bin/rails mtgjson:cleanup_backups
```

## Running Tests

```bash
# Set up test database (first time only)
RAILS_ENV=test bin/rails mtgjson:setup_test

# Run all tests
bin/rspec

# Run specific test file
bin/rspec spec/models/mtgjson/card_spec.rb

# Run specific test by line number
bin/rspec spec/models/mtgjson/card_spec.rb:24
```

## Code Quality

```bash
# Run all CI checks (linting, security scans, tests)
bin/ci

# Run linter with auto-fix
bin/rubocop --fix

# Run security scans individually
bin/brakeman              # Static analysis
bin/bundler-audit         # Gem vulnerabilities
bin/importmap audit       # JS dependencies
```

## Technology Stack

### Backend
- **Rails 8.1** with multi-database support
- **SQLite3** for both application and reference data
- **Solid Cache/Queue/Cable** for caching, background jobs, and WebSockets

### Frontend
- **Hotwire** (Turbo + Stimulus) for reactive UI
- **Tailwind CSS** for styling
- **Importmap** for JavaScript modules
- **Propshaft** asset pipeline

### Testing
- **RSpec** for unit and integration tests
- **Capybara** with Selenium for system tests

### Deployment
- **Kamal** for Docker-based deployment
- **Thruster** HTTP/2 proxy

## Deployment

Collector is configured for deployment with Kamal. See `config/deploy.yml` for configuration.

```bash
# Deploy to production
kamal deploy
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run `bin/ci` to ensure all checks pass
4. Submit a pull request

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0). See [LICENSE](LICENSE) for details.

## Acknowledgments

- Card data provided by [MTGJSON](https://mtgjson.com/)
- Card images from [Scryfall](https://scryfall.com/)
