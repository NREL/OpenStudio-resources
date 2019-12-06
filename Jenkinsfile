@Library('cbci_shared_libs@OpenStudio-resources-CI') _

// We are using the pipeline-github Jenkins plugin
// And we use pullRequest in there, so we need to test whether we are in a PR context
// cf: https://github.com/jenkinsci/pipeline-github-plugin#usage-1

echo "CHANGE_ID=${env.CHANGE_ID}"
echo "CHANGE_TARGET=${env.CHANGE_TARGET}"

if (env.CHANGE_ID) {
  openstudio_resources()
}
