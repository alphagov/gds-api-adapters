#!/usr/bin/env groovy

REPOSITORY = 'gds-api-adapters'

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

  try {
    stage("Checkout gds-api-adapters") {
      echo "Checkout gds-api-adapters branch: ${env.BRANCH_NAME}"
      checkout([
        changelog: false,
        poll: false,
        scm: [
          $class: 'GitSCM',
          branches: [[name: '*/master']],
          doGenerateSubmoduleConfigurations: false,
          extensions: [
            [
              $class: 'RelativeTargetDirectory',
              relativeTargetDir: 'gds-api-adapters'
            ],
          ],
          submoduleCfg: [],
          userRemoteConfigs: [
            [
              credentialsId: 'github-token-govuk-ci-username',
              name: 'origin',
              url: 'https://github.com/alphagov/gds-api-adapters.git'
            ]
          ]
        ]
      ])
    }

    stage("Build") {
      dir("gds-api-adapters") {
        // TODO: I gave up trying to get Jenkins to do this, but maybe it can?
        sh "git checkout ${env.BRANCH_NAME}"
        sh "${WORKSPACE}/gds-api-adapters/jenkins.sh"

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

    stage("Publish pact") {
      dir("gds-api-adapters") {
        withCredentials([
          [
            $class: 'UsernamePasswordMultiBinding',
            credentialsId: 'pact-broker-ci-dev',
            usernameVariable: 'PACT_BROKER_USERNAME',
            passwordVariable: 'PACT_BROKER_PASSWORD'
          ]
        ]) {
          withEnv([
            "PACT_TARGET_BRANCH=branch-${env.BRANCH_NAME}",
            "PACT_BROKER_BASE_URL=https://pact-broker.dev.publishing.service.gov.uk"
          ]) {
            govuk.runRakeTask("pact:publish:branch")
          }
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
              name: '*/master'
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
              credentialsId: 'github-token-govuk-ci-username',
              name: 'publishing-api',
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

        stage("Publish gem") {
          echo 'Publishing gem'
          withCredentials([
            [
              credentialsId: 'github-token-govuk-ci-username',
            ]
          ]) {
            govuk.runRakeTask("publish_gem --trace")
          }
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
