#!/bin/bash
set -e

# Bundle and run tests against multiple ruby versions
for version in 2.3 2.2 2.1; do
  rm -f Gemfile.lock
  export RBENV_VERSION=$version
  echo "Running tests under ruby $version"
  bundle install --path "${HOME}/bundles/${JOB_NAME}"

  # Lint changes introduced in this branch, but not for master
  if [[ ${GIT_BRANCH} != "origin/master" ]]; then
    echo "Running ruby linter for $version"
    bundle exec govuk-lint-ruby \
      --diff \
      --cached \
      --format html --out rubocop-${GIT_COMMIT}.html \
      --format clang
  fi

  bundle exec rake ${TEST_TASK:-"default"}
done
unset RBENV_VERSION
