# masked-email CLI

Generate Fastmail masked email addresses from the command line.

## Setup

Obtain a Fastmail API token: https://www.fastmail.help/hc/en-us/articles/5254602856719-API-tokens

Provide credentials via one of these methods (highest to lowest priority):

1. `--credentials FILE` — plain text file containing only the API key
2. `FASTMAIL_API_KEY` environment variable
3. `~/.fastmail-api-key` — default file location

Install the gem:
```
gem install masked-email
```

## Usage

```
masked-email [options]
```

### Options

| Flag | Description |
|------|-------------|
| `-d, --domain DOMAIN` | **Required.** Domain to create the masked email for |
| `-c, --credentials FILE` | Path to credentials file |
| `-v, --[no-]verbose` | Print full API responses |
| `--dry-run` | Validate credentials and domain without creating an email |
| `-h, --help` | Show help |

## Examples

```bash
# Basic — prints the generated masked email address
masked-email --domain example.com

# Using a custom credentials file
masked-email --domain example.com --credentials ~/.my-fastmail-key

# Using an environment variable
FASTMAIL_API_KEY="your-key" masked-email --domain example.com

# Test your config without creating an email
masked-email --domain example.com --dry-run

# Verbose output (shows API responses)
masked-email --domain example.com --verbose
```

## Output

By default only the generated masked email address is printed:
```
abc123xyz@masked.fastmail.com
```

In verbose mode, full API request/response details are printed alongside the address.
