#!/usr/bin/env groovy
import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

def build(TARGET) {
    // Mark the code build 'stage'....
    stage('Build') {
      def builder = docker.build("openwrt:${env.BUILD_ID}", ".")
      builder.inside("-v ${HOME}/.ccache:/tmp/ccache") {
        // Run build script
        sh "./build.sh ${TARGET}"
      }
    }
}

def publishArtifact(UPLOAD_FILE) {
    //Upload artifact
    stage('Publish artifact') {
      archiveArtifacts artifacts: "${UPLOAD_FILE}"
    }
}

def githubRelease(UPLOAD_FILE, ARCHIVE_NAME) {
    //Upload on github if tag
    sh "git tag --contains `git rev-parse HEAD` > .git-tag"
    def GIT_TAG = readFile('.git-tag').trim()
    sh "rm .git-tag"
    stage('Publish github release') {
        if (!GIT_TAG) {
            Utils.markStageSkippedForConditional(STAGE_NAME)
        } else {
              withCredentials([[$class: 'StringBinding', credentialsId: 'GithubToken', variable: 'GITHUB_TOKEN']]) {
              //withCredentials([usernamePassword(credentialsId: 'GitHubApp',
              //                    usernameVariable: 'GITHUB_APP',
              //                    passwordVariable: 'GITHUB_TOKEN')]) {
              sh "github-release info -u mikysal78 -r ninux-build-openwrt -t ${GIT_TAG} || github-release release -u mikysal78 -r ninux-build-openwrt -t ${GIT_TAG}"
              sh "github-release upload -u mikysal78 -r ninux-build-openwrt -t ${GIT_TAG} -n ${ARCHIVE_NAME} -f ${UPLOAD_FILE}"
            }
        }
    }
}
this
