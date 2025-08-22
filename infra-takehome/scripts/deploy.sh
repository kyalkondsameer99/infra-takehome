#!/usr/bin/env bash

# Apply the 4 spec files in the manifests directory
kubectl apply -f manifests/

# Empty line for readability
echo

# Display a message
echo "Configured cluster"

# Apply the 2 spec files in the samples directory
kubectl apply -f samples/
