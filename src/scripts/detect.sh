#!/bin/bash

jira_status=${JIRA_VAL_STATE:-$JOB_STATUS}

if [[ "$JOB_STATUS" != "failed" && -n "$JIRA_VAL_STATE_SCRIPT" ]]; then
  JIRA_VAL_STATE=$(/bin/bash -c "$JIRA_VAL_STATE_SCRIPT" | tr -d ' ' | tr -d '\n')
  if [[ ! "$JIRA_VAL_STATE" =~ ^(unknown|pending|in_progress|cancelled|failed|rolled_back|successful)$ ]]; then
    echo "Invalid Jira status detected: $JIRA_VAL_STATE"
    exit 1
  fi
fi

if [[ "${JIRA_VAL_JOB_TYPE}" == "build" && "${JIRA_VAL_STATE}" == "rolled_back" ]]; then
  echo "Cannot use 'rolled_back' build job type. Using '${JOB_STATUS}'"
  jira_status="${JOB_STATUS}"
elif [[ "${JIRA_VAL_STATE}" == "unknown" ]]; then
  jira_status="${JOB_STATUS}"
fi

echo "${jira_status}" >/tmp/circleci_jira_status
