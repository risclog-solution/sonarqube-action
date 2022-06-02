#!/bin/bash

set -e

if [[ "${GITHUB_EVENT_NAME}" == "pull_request" ]]; then
	EVENT_ACTION=$(jq -r ".action" "${GITHUB_EVENT_PATH}")
	if [[ "${EVENT_ACTION}" != "opened" ]]; then
		echo "No need to run analysis. It is already triggered by the push event."
		exit
	fi
fi

REPOSITORY_NAME=$(basename "${GITHUB_REPOSITORY}")

[[ ! -z ${INPUT_PASSWORD} ]] && SONAR_PASSWORD="${INPUT_PASSWORD}" || SONAR_PASSWORD=""

if [[ "${INPUT_PROJECTTYPE}" == "python" ]]; then
    ARGS="-Dsonar.exclusions=**/*.js,**/*.css,**/*.scss,**/*.html,**/versions/** \
    -Dsonar.python.coverage.reportPaths="${GITHUB_WORKSPACE}/coverage.xml""
elif [[ "${INPUT_PROJECTTYPE}" == "javascript" ]]; then
    ARGS="-Dsonar.exclusions=**/*.test.js,**/*index.js,src/polyfill.js,src/serviceWorker.js \
    -Dsonar.javascript.lcov.reportPaths="${GITHUB_WORKSPACE}/lcov.info""
else
    exit 1;
fi

if [[ ! -f "${GITHUB_WORKSPACE}/sonar-project.properties" ]]; then
  [[ -z ${INPUT_PROJECTKEY} ]] && SONAR_PROJECTKEY="${REPOSITORY_NAME}" || SONAR_PROJECTKEY="${INPUT_PROJECTKEY}"
  [[ -z ${INPUT_PROJECTNAME} ]] && SONAR_PROJECTNAME="${REPOSITORY_NAME}" || SONAR_PROJECTNAME="${INPUT_PROJECTNAME}"
  [[ -z ${INPUT_PROJECTVERSION} ]] && SONAR_PROJECTVERSION="" || SONAR_PROJECTVERSION="${INPUT_PROJECTVERSION}"
  sonar-scanner \
    -Dsonar.host.url=${INPUT_HOST} \
    -Dsonar.projectKey=${SONAR_PROJECTKEY} \
    -Dsonar.projectName=${SONAR_PROJECTNAME} \
    -Dsonar.projectVersion=${SONAR_PROJECTVERSION} \
    -Dsonar.projectBaseDir=${INPUT_PROJECTBASEDIR} \
    -Dsonar.login=${INPUT_LOGIN} \
    -Dsonar.password=${SONAR_PASSWORD} \
    -Dsonar.sources=./src/ \
    -Dsonar.sourceEncoding=UTF-8 \
    ${ARGS}
else
  sonar-scanner \
    -Dsonar.host.url=${INPUT_HOST} \
    -Dsonar.projectBaseDir=${INPUT_PROJECTBASEDIR} \
    -Dsonar.login=${INPUT_LOGIN} \
    -Dsonar.password=${SONAR_PASSWORD} \
    ${ARGS}
fi
