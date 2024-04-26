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

# JIRA_DEBUG_TEST_COMMIT is only used in testing
HEAD=${JIRA_DEBUG_TEST_COMMIT:-$CIRCLE_SHA1}

if [[ "${JIRA_VAL_JOB_TYPE}" == "deployment" && "$JIRA_BOOL_DETECT_ROLLBACK" == "1" && "$HEAD" != "$(git rev-parse origin/"$CIRCLE_BRANCH")" ]]; then
  # The HEAD of fetched code doesn't match the origin HEAD which is an indicator that
  # this may be a past job that was rerun. This is a typical pattern to roll back
  # code to a previous version. So we get the changes from now until the origin HEAD
  # to find tickets that will not be in this deploy and mark them rolled_back
  echo "Rollback detected..."
  revision_range="$HEAD^..origin/$CIRCLE_BRANCH"
  [[ "$jira_status" == "successful" ]] && jira_status="rolled_back"
else
  # At the HEAD, so get commits between base and now
  revision_range="$JIRA_VAL_BASE_REVISION..$HEAD"
fi

echo "Scanning commits in $revision_range"

git show -s --format='%B' "$revision_range" > /tmp/circleci_jira_commit_messages
echo "${jira_status}" >/tmp/circleci_jira_status
