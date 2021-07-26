#!/usr/bin/env groovy

library("govuk")

node("postgresql-9.6") {

  govuk.setEnvar("PACT_TARGET_BRANCH", "branch-${env.BRANCH_NAME}")
  govuk.setEnvar("PACT_BROKER_BASE_URL", "https://pact-broker.cloudapps.digital")
  govuk.setEnvar("PACT_CONSUMER_VERSION", "branch-${env.BRANCH_NAME}")

  govuk.buildProject(
    extraParameters: [
      stringParam(
        name: 'PUBLISHING_API_BRANCH',
        defaultValue: 'main',
        description: 'Branch of publishing-api to run pacts against'
      ),
      stringParam(
        name: 'COLLECTIONS_BRANCH',
        defaultValue: 'main',
        description: 'Branch of collections to run pacts against'
      ),
      stringParam(
        name: 'FRONTEND_BRANCH',
        defaultValue: 'main',
        description: 'Branch of frontend to run pacts against'
      ),
      stringParam(
        name: 'ACCOUNT_API_BRANCH',
        defaultValue: 'main',
        description: 'Branch of account-api to run pacts against'
      ),
      stringParam(
        name: 'LINK_CHECKER_API_BRANCH',
        defaultValue: 'main',
        description: 'Branch of link-checker-api to run pacts against'
      ),
      stringParam(
        name: 'IMMINENCE_BRANCH',
        defaultValue: 'main',
        description: 'Branch of imminence to run pacts against'
      ),
      stringParam(
        name: 'WHITEHALL_BRANCH',
        defaultValue: 'main',
        description: 'Branch of whitehall to run pacts against'
      )
    ],
    afterTest: {
      withCredentials([
        [
          $class: 'UsernamePasswordMultiBinding',
          credentialsId: 'pact-broker-ci-dev',
          usernameVariable: 'PACT_BROKER_USERNAME',
          passwordVariable: 'PACT_BROKER_PASSWORD'
        ]
      ]) {
        publishPacts(govuk)
        runPactTests(govuk, "publishing-api", PUBLISHING_API_BRANCH, [ resetDatabase: true ])
        runPactTests(govuk, "collections", COLLECTIONS_BRANCH)
        runPactTests(govuk, "frontend", FRONTEND_BRANCH)
        runPactTests(govuk, "account-api", ACCOUNT_API_BRANCH, [ resetDatabase: true ])
        runPactTests(govuk, "link-checker-api", LINK_CHECKER_API_BRANCH, [ resetDatabase: true ])
        runPactTests(govuk, "imminence", IMMINENCE_BRANCH, [ resetDatabase: true, createIndexes: true ])
        runPactTests(govuk, "whitehall", IMMINENCE_BRANCH, [ resetDatabase: true ])
      }
    }
  )
}

def publishPacts(govuk) {
  stage("Publish pacts") {
    govuk.runRakeTask("pact:publish:branch")
  }
}

def runPactTests(govuk, name, branch, options = [ resetDatabase: false, createIndexes: false ]) {
  govuk.checkoutDependent(name, [ branch: branch ]) {
    stage("Run $name pact") {
      govuk.bundleApp()
      lock("$name-$NODE_NAME-test") {
        if (options.resetDatabase) {
          govuk.runRakeTask("db:reset")
        }
        if (options.createIndexes) {
          govuk.runRakeTask("db:mongoid:create_indexes")
        }
        govuk.runRakeTask("pact:verify")
      }
    }
  }
}
