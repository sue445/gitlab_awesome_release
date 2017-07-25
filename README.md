# GitlabAwesomeRelease
Generate changelog from tags and MergeRequests on [GitLab](https://about.gitlab.com/)

[![Gem Version](https://badge.fury.io/rb/gitlab_awesome_release.svg)](https://badge.fury.io/rb/gitlab_awesome_release)
[![Dependency Status](https://gemnasium.com/7f058801015a4fbcf603d936c08836a4.svg)](https://gemnasium.com/19478d2f2735ee355f4c6cd1b8d2c12e)

This is inspired by [GitHub Changelog Generator](https://github.com/skywinder/github-changelog-generator)

## Example
see [CHANGELOG.md](CHANGELOG.md)

## Requirements

* Ruby v2.1+
* GitLab v7.11.0+

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gitlab_awesome_release'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gitlab_awesome_release

## Usage

### `create_note`
generate changelog

```sh
$ gitlab_awesome_release create_note --filename=CHANGELOG.md
```

### options
All options can be specified in both the command arguments and environment variables

* `--gitlab-api-endpoint` , `GITLAB_API_ENDPOINT` **(either one is required)**
  * GitLab API endpoint (e.g. `http://example.com/api/v4`)
* `--gitlab-api-private-token` , `GITLAB_API_PRIVATE_TOKEN` **(either one is required)**
  * Your private token. see [/profile/account](img/private_token.png)
* `--gitlab-project-name` , `GITLAB_PROJECT_NAME` **(either one is required)**
  * Target project (e.g. `group/repo_name`)
* `--from-tag` , `FROM_TAG`
  * The first tag to create a changelog
  * default: oldest tag
* `--to-tag` , `TO_TAG`
  * The last tag to create a changelog
  * default: latest tag
* `--filename` , `FILENAME`
  * Filepath to changelog file (e.g. `CHANGELOG.md`)
  * if empty, output to console
* `--allow-tag-format` , `ALLOW_TAG_FORMAT`
  * Tag format for release note heading (regular expresion pattern)
  * default: `^v?[\d.]+`
* `--log-level` , `LOG_LEVEL`
  * Log level `(debug|info|warn|error|fatal|unknown)`
  * default: `info`

### `create_latest_note`
generate release note only latest version and unreleased

```sh
$ gitlab_awesome_release create_latest_note
```

### options
All options can be specified in both the command arguments and environment variables

* `--gitlab-api-endpoint` , `GITLAB_API_ENDPOINT` **(either one is required)**
  * GitLab API endpoint (e.g. `http://example.com/api/v4`)
* `--gitlab-api-private-token` , `GITLAB_API_PRIVATE_TOKEN` **(either one is required)**
  * Your private token. see [/profile/account](img/private_token.png)
* `--gitlab-project-name` , `GITLAB_PROJECT_NAME` **(either one is required)**
  * Target project (e.g. `group/repo_name`)
* `--filename` , `FILENAME`
  * Filepath to changelog file (e.g. `CHANGELOG.md`)
  * if empty, output to console
* `--allow-tag-format` , `ALLOW_TAG_FORMAT`
  * Tag format for release note heading (regular expresion pattern)
  * default: `^v?[\d.]+`
* `--log-level` , `LOG_LEVEL`
  * Log level `(debug|info|warn|error|fatal|unknown)`
  * default: `info`

### marking
Add version label to MergeRequests

example) https://gitlab.com/sue445/gitlab_awesome_release/merge_requests?state=merged

```sh
$ gitlab_awesome_release marking --from-tag=v0.1.0 --to-tag=v0.2.0
```

### options
All options can be specified in both the command arguments and environment variables

* `--gitlab-api-endpoint` , `GITLAB_API_ENDPOINT` **(either one is required)**
  * GitLab API endpoint (e.g. `http://example.com/api/v4`)
* `--gitlab-api-private-token` , `GITLAB_API_PRIVATE_TOKEN` **(either one is required)**
  * Your private token. see [/profile/account](img/private_token.png)
* `--gitlab-project-name` , `GITLAB_PROJECT_NAME` **(either one is required)**
  * Target project (e.g. `group/repo_name`)
* `--from-tag` , `FROM_TAG` **(either one is required)**
  * The first tag to marking
* `--to-tag` , `TO_TAG` **(either one is required)**
  * The last tag to marking
* `--label` , `LABEL`
  * Label to be added to the MergeRequest
  * default: `--to-tag` or `TO_TAG`
* `--log-level` , `LOG_LEVEL`
  * Log level `(debug|info|warn|error|fatal|unknown)`
  * default: `info`

## ProTip
Environment variables read from `~/.env.gitlab` and current `.env.gitlab`

`~/.env.gitlab`

```
GITLAB_API_ENDPOINT=http://example.com/api/v4
GITLAB_API_PRIVATE_TOKEN=XXXXXXXXXXXXXXXXXXX
ALLOW_TAG_FORMAT=^v?[\d.]+
```

current `.env.gitlab`

```
GITLAB_PROJECT_NAME=group/name
ALLOW_TAG_FORMAT=^v?[\d.]+
```

If defined both `~/.env.gitlab` and current `.env.gitlab`, current `.env.gitlab` is priority


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec gitlab_awesome_release` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://gitlab.com/sue445/gitlab_awesome_release.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

