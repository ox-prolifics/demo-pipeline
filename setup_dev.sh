#!/bin/bash
# Setup Development Project

echo "Setting up Tasks Development Environment in project tasks-dev"

# Set up Dev Project
oc policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n tasks-dev

# Set up Dev Application
# oc new-build --binary=true --name="tasks" jboss-eap71-openshift:1.3 -n tasks-dev
oc new-build --binary=true --name="tasks" --image-stream=openshift/jboss-eap71-openshift:1.1 -n tasks-dev
oc new-app tasks-dev/tasks:0.0-0 --name=tasks --allow-missing-imagestream-tags=true -n tasks-dev
oc set triggers dc/tasks --remove-all -n tasks-dev
oc expose dc tasks --port 8080 -n tasks-dev
oc expose svc tasks -n tasks-dev
oc create configmap tasks-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n tasks-dev
oc set volume dc/tasks --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=tasks-config -n tasks-dev
oc set volume dc/tasks --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=tasks-config -n tasks-dev
oc set probe dc/tasks --readiness --get-url=http://:8080/ --initial-delay-seconds=30 --timeout-seconds=1 -n tasks-dev
oc set probe dc/tasks --liveness --get-url=http://:8080/ --initial-delay-seconds=30 --timeout-seconds=1 -n tasks-dev

oc patch -n tasks-dev dc tasks --patch='{"spec":{"template":{"spec":{"containers":[{"name":"tasks","resources":{"limits":{"cpu":"1","memory":"1356Mi"},"requests":{"cpu":"1","memory":"1356Mi"}}}]}}}}'
