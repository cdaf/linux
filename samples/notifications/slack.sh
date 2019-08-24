#!/bin/bash

function post_to_slack () {
  # format message as a code block ```${msg}```
  SLACK_MESSAGE="\`\`\`$1\`\`\`"
  SLACK_URL=https://hooks.slack.com/services/your-service-identifier-part-here
 
  case "$2" in
    INFO)
      SLACK_ICON=':slack:'
      ;;
    WARNING)
      SLACK_ICON=':warning:'
      ;;
    ERROR)
      SLACK_ICON=':bangbang:'
      ;;
    *)
      SLACK_ICON=':slack:'
      ;;
  esac
 
  curl -X POST --data "payload={\"text\": \"${SLACK_ICON} ${SLACK_MESSAGE}\"}" ${SLACK_URL}
}

post_to_slack "Hello, World" "INFO"
exit 0
