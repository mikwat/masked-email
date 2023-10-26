# Masked Email

A simple command-line script for generating masked email addresses via Fastmail.

## Installation

```
gem install masked-email
```

## Usage
```
$ masked-email --help
Usage: masked-email [options]
    -d, --domain DOMAIN              Domain to create email for
    -c, --credentials FILE           Credentials file
    -v, --[no-]verbose               Run verbosely
        --dry-run                    Dry run
    -h, --help                       Prints this help
```

### Credentials

Credentials can either be provided in a file or via an environment variable.

```
$ masked-email --credentials .credentials ...
```

```
$ FASTMAIL_API_KEY=... masked-email ...
```
