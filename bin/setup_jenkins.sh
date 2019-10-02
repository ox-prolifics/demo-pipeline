#!/bin/bash
# Setup Jenkins Project

REPO=$1
CLUSTER=$2
echo "Setting up Jenkins in project jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Set up Jenkins with sufficient resources
oc new-app jenkins-persistent \
  --param ENABLE_OAUTH=true \
  --param MEMORY_LIMIT=2Gi \
  --param VOLUME_CAPACITY=4Gi \
  --param DISABLE_ADMINISTRATIVE_MONITORS=true \
  -n jenkins
oc set resources dc jenkins --limits=memory=2Gi,cpu=2 --requests=memory=1Gi,cpu=500m -n $GUID-jenkins

# Create custom agent container image with skopeo
oc new-build -D \
$'FROM docker.io/openshift/jenkins-agent-maven-35-centos7:v3.11\n
USER root\n 
RUN yum -y install skopeo && yum clean all\n 
USER 1001' \
  --name=jenkins-agent-appdev -n jenkins

# Create pipeline build config pointing to the ${REPO} with contextDir `openshift-tasks`
echo "apiVersion: v1
items:
- kind: "BuildConfig"
  apiVersion: "v1"
  metadata:
    name: "tasks-pipeline"
  spec:
    source:
      contextDir: "openshift-tasks"
      type: "Git"
      git:
        uri: ${REPO}
    strategy:
      type: JenkinsPipeline
      jenkinsPipelineStrategy:
        jenkinsfilePath: Jenkinsfile
kind: List
metadata: []" | oc create -f - -n jenkins

# For some reason the buildconfig wouldn't accept these env vars in the yaml, setting them works fine
oc -n jenkins set env bc/tasks-pipeline REPO=$REPO
oc -n jenkins set env bc/tasks-pipeline CLUSTER=$CLUSTER

# Make sure that Jenkins is fully up and running before proceeding!
while : ; do
  echo "Checking if Jenkins is Ready..."
  AVAILABLE_REPLICAS=$(oc get dc jenkins -n jenkins -o=jsonpath='{.status.availableReplicas}')
  if [[ "$AVAILABLE_REPLICAS" == "1" ]]; then
    echo "...Yes. Jenkins is ready."
    break
  fi
  echo "...no. Sleeping 10 seconds."
  sleep 10
done