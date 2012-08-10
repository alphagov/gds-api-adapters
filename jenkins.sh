#!/bin/bash -x
set -e

echo "Gnnnnarrrrrrrrrgh!"
exit 1

bundle install --path "${HOME}/bundles/${JOB_NAME}"
bundle exec rake test
bundle exec rake publish_gem
