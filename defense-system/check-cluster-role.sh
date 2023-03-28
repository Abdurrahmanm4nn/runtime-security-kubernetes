#!/bin/bash

# Test if roles are set correctly
kubectl auth can-i list deployments  # no
kubectl auth can-i delete pod  # yes
kubectl access-matrix  # github.com/corneliusweig/rakkess