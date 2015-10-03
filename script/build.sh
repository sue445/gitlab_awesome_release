#!/bin/bash -xe

export CI=true

bundle check --path=vendor/bundle || bundle install --path=vendor/bundle --jobs=2 --retry=3

bundle exec rspec
