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
        defaultValue: 'master',
        description: 'Branch of publishing-api to run pacts against'
      ),
      stringParam(
        name: 'COLLECTIONS_BRANCH',
        defaultValue: 'main',
        description: 'Branch of collections to run pacts against'
      ),
      stringParam(
        name: 'FRONTEND_BRANCH',
        defaultValue: 'master',
        description: 'Branch of frontend to run pacts against'
      ),
      stringParam(
        name: 'ACCOUNT_API_BRANCH',
        defaultValue: 'main',
        description: 'Branch of account-api to run pacts against'
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
      }
    }
  )
}

def publishPacts(govuk) {
  stage("Publish pacts") {
    govuk.runRakeTask("pact:publish:branch")
  }
}

def runPactTests(govuk, name, branch, options = [ resetDatabase: false ]) {
  govuk.checkoutDependent(name, [ branch: branch ]) {
    stage("Run $name pact") {
      govuk.bundleApp()
      lock("$name-$NODE_NAME-test") {
        if (options.resetDatabase) {
          govuk.runRakeTask("db:reset")
        }
        govuk.runRakeTask("pact:verify")
      }
    }
  }
}
