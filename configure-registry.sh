#!/bin/bash

# Create a PVC for the image registry
cat << EOF | oc create -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: image-registry-storage 
  namespace: openshift-image-registry 
spec:
  accessModes:
  - ReadWriteOnce 
  resources:
    requests:
      storage: 100Gi
EOF

# Make the image registry managed
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'
# Allow block storage for the registry
oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"rolloutStrategy":"Recreate","replicas":1}}'
# Link the claim above to the image resgitry
oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"storage":{"pvc":{"claim":"image-registry-storage"}}}}'
# Exposing OCP default registry route
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge