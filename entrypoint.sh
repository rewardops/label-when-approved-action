#!/bin/bash
set -e

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
  exit 1
fi

if [[ -z "$GITHUB_REPOSITORY" ]]; then
  echo "Set the GITHUB_REPOSITORY env variable."
  exit 1
fi

if [[ -z "$GITHUB_EVENT_PATH" ]]; then
  echo "Set the GITHUB_EVENT_PATH env variable."
  exit 1
fi

addLabel=$ADD_LABEL
if [[ -n "$LABEL_NAME" ]]; then
  echo "Warning: Plase define the ADD_LABEL variable instead of the deprecated LABEL_NAME."
  addLabel=$LABEL_NAME
fi

if [[ -z "$addLabel" ]]; then
  echo "Set the ADD_LABEL or the LABEL_NAME env variable."
  exit 1
fi

addLabel2=$ADD_LABEL2
if [[ -n "$LABEL_NAME" ]]; then
  echo "Warning: Plase define the ADD_LABEL2 variable instead of the deprecated LABEL_NAME2."
  addLabel2=$LABEL_NAME2
fi

if [[ -z "$addLabel2" ]]; then
  echo "Set the ADD_LABEL2 or the LABEL_NAME2 env variable."
  exit 1
fi

URI="https://api.github.com"
API_HEADER="Accept: application/vnd.github.v3+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")
state=$(jq --raw-output .review.state "$GITHUB_EVENT_PATH")
number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")

label_when_approved() {
  # https://developer.github.com/v3/pulls/reviews/#list-reviews-on-a-pull-request
  body1=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${number}/reviews?per_page=100")
  reviews=$(echo "$body1" | jq --raw-output '.[] | {state: .state} | @base64')

  body2=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${number}/requested_reviewers?per_page=100")
  requested_reviewers=$(echo "body2" | jq '.users | length')
  
  approvals=0

  for r in $reviews; do
    review="$(echo "$r" | base64 -d)"
    rState=$(echo "$review" | jq --raw-output '.state')
  

    if [[ "$rState" == "APPROVED" ]]; then
      approvals=$((approvals+1))
    fi

    echo "${approvals}/${requested_reviewers} approvals"

    if [[ "$approvals" -gt "$requested_reviewers" ]]; then
      echo "Labeling pull request"

      curl -sSL \
        -H "${AUTH_HEADER}" \
        -H "${API_HEADER}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"labels\":[\"${addLabel}\",\"${addLabel2}\"]}" \
        "${URI}/repos/${GITHUB_REPOSITORY}/issues/${number}/labels"

      if [[ -n "$REMOVE_LABEL" ]]; then
          curl -sSL \
            -H "${AUTH_HEADER}" \
            -H "${API_HEADER}" \
            -X DELETE \
            "${URI}/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/${REMOVE_LABEL}"
      fi

      break
    fi
  done
}

if [[ "$action" == "submitted" ]] && [[ "$state" == "approved" ]]; then
  label_when_approved
else
  echo "Ignoring event ${action}/${state}"
fi
