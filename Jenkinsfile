#!/usr/bin/env groovy

library("govuk")

node("postgresql-9.6") {

  def pact_branch = (env.BRANCH_NAME == 'master' ? 'master' : "branch-${env.BRANCH_NAME}")
  govuk.setEnvar("PACT_TARGET_BRANCH", pact_branch)
  govuk.setEnvar("PACT_BROKER_BASE_URL", "https://pact-broker.cloudapps.digital")

  govuk.buildProject(
    extraParameters: [
      stringParam(
        name: 'PUBLISHING_API_BRANCH',
        defaultValue: 'master',
        description: 'Branch of publishing-api to run pacts against'
      ),
      stringParam(
        name: 'COLLECTIONS_BRANCH',
        defaultValue: 'master',
        description: 'Branch of collections to run pacts against'
      ),
      stringParam(
        name: 'FRONTEND_BRANCH',
        defaultValue: 'master',
        description: 'Branch of frontend to run pacts against'
      ),
      stringParam(
        name: 'FRONTEND_PACT_URI',
        description: 'Local pactfile for Frontend to test against (will test against Pact Broker if left blank). Example: "../gds-api-adapters/spec/pacts/gds_api_adapters-bank_holidays_api.json"'
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
        publishPacts(govuk, env.BRANCH_NAME == 'master')
        runPublishingApiPactTests(govuk)
        runCollectionsPactTests(govuk)
        runFrontendPactTests(govuk)
      }
    }
  )
}

def publishPacts(govuk, releasedVersion) {
  stage("Publish pacts") {
    govuk.runRakeTask("pact:publish:branch")
  }
}

def runPublishingApiPactTests(govuk) {
  govuk.checkoutDependent("publishing-api", [ branch: PUBLISHING_API_BRANCH ]) {
    stage("Run publishing-api pact") {
      govuk.bundleApp()
      lock("publishing-api-$NODE_NAME-test") {
        govuk.runRakeTask("db:reset")
        govuk.runRakeTask("pact:verify:branch[${env.BRANCH_NAME}]")
      }
    }
  }
}

def runCollectionsPactTests(govuk){
  govuk.checkoutDependent("collections", [ branch: COLLECTIONS_BRANCH ]) {
    stage("Run collections pact") {
      govuk.bundleApp()
      lock("collections-$NODE_NAME-test") {
        govuk.runRakeTask("pact:verify:branch[${env.BRANCH_NAME}]")
      }
    }
  }
}

def runFrontendPactTests(govuk){
  govuk.checkoutDependent("frontend", [ branch: FRONTEND_BRANCH ]) {
    stage("Run frontend pact") {
      environment { 
        PACT_URI = FRONTEND_PACT_URI
      }
      govuk.bundleApp()
      lock("frontend-$NODE_NAME-test") {
        govuk.runRakeTask("pact:verify")
      }
    }
  }
}
