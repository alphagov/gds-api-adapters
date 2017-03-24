#!/usr/bin/env groovy

REPOSITORY = 'gds-api-adapters'

def rubyVersions = [
  '2.1',
  '2.2',
  '2.3',
]

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'
  properties([
    parameters([
      stringParam(
        defaultValue: 'master',
        description: 'Branch of publishing-api to run pacts against',
        name: 'PUBLISHING_API_BRANCH'
      ),
    ])
  ])

  try {
    govuk.initializeParameters([
      'PUBLISHING_API_BRANCH': 'master',
    ])
    def pact_branch = (env.BRANCH_NAME == 'master' ? 'master' : "branch-${env.BRANCH_NAME}")
    govuk.setEnvar("PACT_TARGET_BRANCH", pact_branch)
    govuk.setEnvar("PACT_BROKER_BASE_URL", "https://pact-broker.cloudapps.digital")

    stage("Checkout gds-api-adapters") {
      checkout([
        $class: 'GitSCM',
        branches: scm.branches,
        extensions: [
          [$class: 'RelativeTargetDirectory',
           relativeTargetDir: 'gds-api-adapters'],
          [$class: 'CleanCheckout'],
        ],
        userRemoteConfigs: scm.userRemoteConfigs
      ])
      dir('gds-api-adapters') {
        govuk.mergeMasterBranch()
      }
    }

    for (rubyVersion in rubyVersions) {
      stage("Test with ruby $rubyVersion") {
        dir("gds-api-adapters") {
          sh "rm -f Gemfile.lock"
          govuk.setEnvar("RBENV_VERSION", rubyVersion)
          govuk.bundleGem()

          govuk.rubyLinter("lib spec test")

          govuk.runTests()

          publishHTML(target: [
            allowMissing: false,
            alwaysLinkToLastBuild: false,
            keepAll: true,
            reportDir: 'coverage/rcov',
            reportFiles: 'index.html',
            reportName: 'RCov Report'
          ])
        }
      }
    }
    sh "unset RBENV_VERSION"

    stage("Publish branch pact") {
      dir("gds-api-adapters") {
        withCredentials([
          [
            $class: 'UsernamePasswordMultiBinding',
            credentialsId: 'pact-broker-ci-dev',
            usernameVariable: 'PACT_BROKER_USERNAME',
            passwordVariable: 'PACT_BROKER_PASSWORD'
          ]
        ]) {
          govuk.runRakeTask("pact:publish:branch")
        }
      }
    }

    stage("Checkout publishing-api") {
      checkout([
        changelog: false,
        poll: false,
        scm: [
          $class: 'GitSCM',
          branches: [
            [
              name: PUBLISHING_API_BRANCH
            ]
          ],
          doGenerateSubmoduleConfigurations: false,
          extensions: [
            [
              $class: 'RelativeTargetDirectory',
              relativeTargetDir: 'publishing-api'
            ]
          ],
          submoduleCfg: [],
          userRemoteConfigs: [
            [
              url: 'https://github.com/alphagov/publishing-api.git'
            ]
          ]
        ]
      ])

      dir("publishing-api") {
        govuk.contentSchemaDependency('deployed-to-production')
        govuk.setEnvar("GOVUK_CONTENT_SCHEMAS_PATH", "tmp/govuk-content-schemas")
      }
    }

    stage("Run publishing-api pact") {
      dir("publishing-api") {
        withEnv(["JOB_NAME=publishing-api"]) { // TODO: This environment is a hack
          govuk.bundleApp()
        }
        withCredentials([
          [
            $class: 'UsernamePasswordMultiBinding',
            credentialsId: 'pact-broker-ci-dev',
            usernameVariable: 'PACT_BROKER_USERNAME',
            passwordVariable: 'PACT_BROKER_PASSWORD'
          ]
        ]) {
          govuk.runRakeTask("db:reset")
          govuk.runRakeTask("pact:verify:branch[${env.BRANCH_NAME}]")
        }
      }
    }

    if (env.BRANCH_NAME == 'master') {
      dir("gds-api-adapters") {
        stage("Push release tag") {
          echo 'Pushing tag'
          govuk.pushTag(REPOSITORY, env.BRANCH_NAME, 'release_' + env.BUILD_NUMBER)
        }

        stage("Publish released version pact") {
          echo 'Publishing pact'
          withCredentials([
            [
              $class: 'UsernamePasswordMultiBinding',
              credentialsId: 'pact-broker-ci-dev',
              usernameVariable: 'PACT_BROKER_USERNAME',
              passwordVariable: 'PACT_BROKER_PASSWORD'
            ]
          ]) {
            govuk.runRakeTask("pact:publish:released_version")
          }
        }

        stage("Publish gem") {
          echo 'Publishing gem'
          govuk.publishGem(REPOSITORY, env.BRANCH_NAME)
        }
      }
    }
  } catch (e) {
    currentBuild.result = "FAILED"
    step([$class: 'Mailer',
          notifyEveryUnstableBuild: true,
          recipients: 'govuk-ci-notifications@digital.cabinet-office.gov.uk',
          sendToIndividuals: true])
    throw e
  }
}
