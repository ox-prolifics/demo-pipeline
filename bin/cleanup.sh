#!/bin/bash
# Delete all Projects

echo "Removing all Pipeline Projects"
oc delete project jenkins
oc delete project tasks-dev
oc delete project tasks-prod
