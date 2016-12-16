#!/bin/bash

export PACT_BROKER_BASE_URL=${PACT_BROKER_BASE_URL:-"https://pact-broker.dev.publishing.service.gov.uk"}

# Cleanup anything left from previous test runs
git clean -fdx

# Try to merge master into the current branch, and abort if it doesn't exit
# cleanly (ie there are conflicts). This will be a noop if the current branch
# is master.
git merge --no-commit origin/master || git merge --abort

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

if [ -n "$PACT_TARGET_BRANCH" ]; then
  bundle exec rake pact:publish:branch
fi

if [[ -n "$PUBLISH_GEM" ]]; then
  bundle install --path "${HOME}/bundles/${JOB_NAME}"
  bundle exec rake publish_gem --trace
fi
