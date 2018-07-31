#!/usr/bin/env groovy

library("govuk")

node {

  def pact_branch = (env.BRANCH_NAME == 'master' ? 'master' : "branch-${env.BRANCH_NAME}")
  govuk.setEnvar("PACT_TARGET_BRANCH", pact_branch)
  govuk.setEnvar("PACT_BROKER_BASE_URL", "https://pact-broker.cloudapps.digital")

  govuk.buildProject(
    rubyListDiff: false,
    extraParameters: [
      stringParam(
        name: 'PUBLISHING_API_BRANCH',
        defaultValue: 'master',
        description: 'Branch of publishing-api to run pacts against'
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
        publishBranchPact(govuk)
        runPublishingApiPactTests(govuk)
      }
    }
  )
}

def publishBranchPact(govuk) {
  stage("Publish branch pact") {
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
