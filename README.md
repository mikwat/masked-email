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

The default location for credentials is `~/.fastmail-api-key`. This file
should contain just the value of an API key which can be created by following
the instructions at: https://www.fastmail.help/hc/en-us/articles/5254602856719-API-tokens.

Alternatively, the location of the credentials file can be specified with the
`--credentials` option:
```
$ masked-email --credentials .credentials ...
```

Finally, the API key can be specified on the environment as `FASTMAIL_API_KEY`:
```
$ FASTMAIL_API_KEY=... masked-email ...
```
