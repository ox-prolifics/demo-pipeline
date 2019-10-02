#!/bin/bash
# Create Projects.
# When FROM_JENKINS=true then project ownership is set to USER
# Set FROM_JENKINS=false for testing outside of the Grading Jenkins

USER=$1
FROM_JENKINS=$2

echo "Creating Projects"
oc new-project jenkins    --display-name="Jenkins"
oc new-project tasks-dev  --display-name="Tasks Development"
oc new-project tasks-prod --display-name="Tasks Production"

if [ "$FROM_JENKINS" = "true" ]; then
  oc policy add-role-to-user admin ${USER} -n jenkins
  oc policy add-role-to-user admin ${USER} -n tasks-dev
  oc policy add-role-to-user admin ${USER} -n tasks-prod

  oc annotate namespace jenkins    openshift.io/requester=${USER} --overwrite
  oc annotate namespace tasks-dev  openshift.io/requester=${USER} --overwrite
  oc annotate namespace tasks-prod openshift.io/requester=${USER} --overwrite
fi
