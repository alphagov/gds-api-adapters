#!/bin/bash -x
set -e
rm -f Gemfile.lock

export GOVUK_APP_DOMAIN=dev.gov.uk

for version in 2.2 2.1 1.9.3; do
  export RBENV_VERSION=$version
  echo "Running tests under ruby $version"
  bundle install --path "${HOME}/bundles/${JOB_NAME}"
  bundle exec rake
done

unset RBENV_VERSION

if [[ -n "$PUBLISH_GEM" ]]; then
  bundle exec rake publish_gem --trace
fi
