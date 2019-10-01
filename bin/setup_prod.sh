#!/bin/bash
# Setup Production Project (initial active services: Green)

echo "Setting up Tasks Production Environment in project tasks-prod"

# Set up Production Project
oc policy add-role-to-group system:image-puller system:serviceaccounts:tasks-prod -n tasks-dev
oc policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n tasks-prod

# Create Blue Application
oc new-app tasks-dev/tasks:0.0 --name=tasks-blue --allow-missing-imagestream-tags=true -n tasks-prod
oc set triggers dc/tasks-blue --remove-all -n tasks-prod
oc expose dc tasks-blue --port 8080 -n tasks-prod
oc create configmap tasks-blue-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n tasks-prod
oc set volume dc/tasks-blue --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=tasks-blue-config -n tasks-prod
oc set volume dc/tasks-blue --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=tasks-blue-config -n tasks-prod
oc set probe dc/tasks-blue --readiness --get-url=http://:8080/ --initial-delay-seconds=30 --timeout-seconds=1 -n tasks-prod
oc set probe dc/tasks-blue --liveness --get-url=http://:8080/ --initial-delay-seconds=30 --timeout-seconds=1 -n tasks-prod
# Setting 'wrong' VERSION. This will need to be updated in the pipeline
oc set env dc/tasks-blue VERSION='0.0 (tasks-blue)' -n tasks-prod


# Create Green Application
oc new-app tasks-dev/tasks:0.0 --name=tasks-green --allow-missing-imagestream-tags=true -n tasks-prod
oc set triggers dc/tasks-green --remove-all -n tasks-prod
oc expose dc tasks-green --port 8080 -n tasks-prod
oc create configmap tasks-green-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n tasks-prod
oc set volume dc/tasks-green --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=tasks-green-config -n tasks-prod
oc set volume dc/tasks-green --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=tasks-green-config -n tasks-prod
oc set probe dc/tasks-green --readiness --get-url=http://:8080/ --initial-delay-seconds=30 --timeout-seconds=1 -n tasks-prod
oc set probe dc/tasks-green --liveness --get-url=http://:8080/ --initial-delay-seconds=30 --timeout-seconds=1 -n tasks-prod

# Update resource requests/limits in dc
oc patch -n tasks-prod dc tasks-green --patch='{"spec":{"template":{"spec":{"containers":[{"name":"tasks-green","resources":{"limits":{"cpu":"1","memory":"1356Mi"},"requests":{"cpu":"1","memory":"1356Mi"}}}]}}}}'
oc patch -n tasks-prod dc tasks-blue --patch='{"spec":{"template":{"spec":{"containers":[{"name":"tasks-blue","resources":{"limits":{"cpu":"1","memory":"1356Mi"},"requests":{"cpu":"1","memory":"1356Mi"}}}]}}}}'

# Expose Blue service as route to make green application active
oc expose svc/tasks-green --name tasks -n tasks-prod