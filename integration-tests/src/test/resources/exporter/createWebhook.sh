#!/bin/bash
# Copyright (c) 2019, 2020, Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upload
monitoringExporterDir=$1
domainNS=$3
domainNS1=$4
resourceExporterDir=$2
monitoringExporterEndToEndDir=${monitoringExporterDir}/src/samples/kubernetes/end2end

cd ${monitoringExporterEndToEndDir}
docker build ./webhook -t webhook-log:1.0;
if [ ${SHARED_CLUSTER} = "true" ]; then
    docker login $REPO_REGISTRY -u $REPO_USERNAME -p $REPO_PASSWORD
    echo "tag image " $REPO_REGISTRY/$REPO_USERNAME/webhook-log:1.0
    docker tag webhook-log:1.0 $REPO_REGISTRY/weblogick8s/webhook-log:1.0
    docker push $REPO_REGISTRY/weblogick8s/webhook-log:1.0
    if [ ! "$?" = "0" ] ; then
       echo "Error: Could not push the image to $REPO_REGISTRY".
      #exit 1
    fi
    sed -i "s/webhook-log:1.0/$REPO_REGISTRY\/weblogick8s\/webhook-log:1.0/g"  ${resourceExporterDir}/server.yaml
    sed -i "s/IfNotPresent/Always/g"  ${resourceExporterDir}/server.yaml
fi

kubectl create ns webhook
if [ ${SHARED_CLUSTER} = "true" ]; then
    kubectl create secret docker-registry ocirsecret -n webhook \
                        --docker-server=$REPO_REGISTRY \
                        --docker-username=$REPO_USERNAME \
                        --docker-password=$REPO_PASSWORD \
                        --docker-email=$REPO_EMAIL  \
                        --dry-run -o yaml | kubectl apply -f -
fi

kubectl apply -f ${resourceExporterDir}/server.yaml --validate=false
echo "Getting info about webhook"
kubectl get pods -n webhook

echo "Run the script [createWebhook.sh] ..."
