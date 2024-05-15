#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

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

base64_encoded_no_auth=$(echo '{"authType":"BASIC_AUTH","credentials":{"username":"","password":""}}' | base64)

# Create the secret and config YAML
cat << EOF | oc create -f -
kind: Secret
apiVersion: v1
metadata:
  name: github-no-auth
  namespace: ace
  labels:
    app.kubernetes.io/component: configuration
    app.kubernetes.io/instance: github-no-auth
    app.kubernetes.io/name: github-no-auth
    appconnect.ibm.com/kind: Configuration
data:
  configuration: $base64_encoded_no_auth
type: Opaque
---
apiVersion: appconnect.ibm.com/v1beta1
kind: Configuration
metadata:
  name: github-no-auth
  namespace: ace
spec:
  secretName: github-no-auth
  type: barauth
  version: 12.0.12.0-r1
EOF

# Deploy ACE using the YAML file
echo "Deploying ACE..."
cat << EOF | oc create -f -
kind: IntegrationRuntime
apiVersion: appconnect.ibm.com/v1beta1
metadata:
  name: server-ping
  namespace: ace
spec:
  barURL:
    - 'https://github.com/jeremybeucler-ibm/customer-demo/raw/main/bars/serverPing.bar'
  configurations:
    - github-no-auth
  license:
    accept: true
    license: L-QECF-MBXVLU
    use: CloudPakForIntegrationNonProduction
  replicas: 1
  version: '12.0.12.0-r1'
  flowType:
    toolkitFlow: true
EOF

#Get the route
route=`oc get route | grep server-ping-http- | awk '{print $2}'`
#Get the base path
base=`oc exec $(oc get pods -o name -n ace | grep server-ping) -- cat /workdir-shared/ace-server/run/ping_test/swagger.json | jq -r '.basePath'`
#Get the path
path=`oc exec $(oc get pods -o name -n ace | grep server-ping) -- cat /workdir-shared/ace-server/run/ping_test/swagger.json | jq -r '.paths | to_entries | .[] | .key'`
#Curl to test
curl $route$base$path
