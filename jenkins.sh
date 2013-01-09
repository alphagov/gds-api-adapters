#!/bin/bash -x
set -e
bundle install --path "${HOME}/bundles/${JOB_NAME}"
export GOVUK_APP_DOMAIN=dev.gov.uk
bundle exec rake test
bundle exec rake publish_gem
