#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
if ! podman login -u kubeadmin -p "$(oc whoami -t)" --tls-verify=false $HOST; then
    echo "Failed to login to the registry. Exiting."
    exit 1
fi

# Define the project name
PROJECT_NAME="ace"
if oc get project "$PROJECT_NAME" &>/dev/null; then
    oc project "$PROJECT_NAME"
    echo "Project '$PROJECT_NAME' already exists."
else
    # Create the project if it doesn't exist
    oc new-project "$PROJECT_NAME"
    echo "Project '$PROJECT_NAME' created."
fi

#Build and push docker image
ibm_registry_username="$(oc get secrets ibm-entitlement-key -o json | jq -r '.data[".dockerconfigjson"]' | base64 -d | jq -r '.auths["cp.icr.io"].username')"
ibm_registry_password="$(oc get secrets ibm-entitlement-key -o json | jq -r '.data[".dockerconfigjson"]' | base64 -d | jq -r '.auths["cp.icr.io"].password')"
podman login cp.icr.io -u "$ibm_registry_username" -p "$ibm_registry_password"
podman login "$HOST" -u kubeadmin -p "$(oc whoami -t)" --tls-verify=false

podman build -t server-ping-baked . --platform=linux/amd64
echo "Build Succeeded"

podman tag server-ping-baked "$HOST"/"$PROJECT_NAME"/server-ping-baked:1.0
echo "Tag Succeeded"

podman push "$HOST"/"$PROJECT_NAME"/server-ping-baked:1.0 --tls-verify=false
echo "ACE image has been pushed to OpenShift registry."

# Deploy the Integration Runtime
echo "Deploying ACE..."
cat << EOF | oc create -f -
apiVersion: appconnect.ibm.com/v1beta1
kind: IntegrationRuntime
metadata:
  name: server-ping-baked
  namespace: ace
spec:
  license:
    accept: true
    license: L-QECF-MBXVLU
    use: CloudPakForIntegrationNonProduction
  template:
    spec:
      containers:
        - resources:
          name: runtime
          image: image-registry.openshift-image-registry.svc:5000/ace/server-ping-baked:1.0
  replicas: 1
  version: '12.0.12.0-r1'
  flowType:
    toolkitFlow: true
EOF

#TEST
#curl http://server-ping-baked-http-ace.apps.ocpinstall.gym.lan/ping_test/v1/server