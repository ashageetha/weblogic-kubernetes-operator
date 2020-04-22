#!/bin/bash
# Copyright (c) 2019, 2020, Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#
# This script deploys the domain resoure in WORKDIR/mii-DOMAIN_UID.yaml.
# If "-predelete" is specified, it also deletes any existing domain and 
# waits for the existing domain's pods to exit prior to deploying.
#
# Optional parameter:
#   -predelete             - Delete the existing domain (if any) and
#                            wait for its pods to exit before deploying.
#
# Optional environment variables:
#   WORKDIR                - Working directory for the sample with at least
#                            10GB of space. Defaults to 
#                            '/tmp/$USER/model-in-image-sample-work-dir'.
#   DOMAIN_UID             - Defaults to 'sample-domain1'
#   DOMAIN_NAMESPACE       - Defaults to 'sample-domain1-ns'
#

set -eu
set -o pipefail

SCRIPTDIR="$( cd "$(dirname "$0")" > /dev/null 2>&1 ; pwd -P )"

source $SCRIPTDIR/env-init.sh

pre_delete=false
dry_run=false

while [ ! -z "${1:-}" ]; do
  case "${1:-}" in
    -predelete) pre_delete=true ;;
    -dryrun) dry_run=true ;;
    *) echo "@@ Error: Unknown parameter '$1'. Optionally pass '-predelete' or '-dryrun'." ; exit 1; ;;
  esac
  shift
done

#
# If "-predelete" is set, then delete the existing running domain (if any)
# and wait for its pods to exit.
#

if [ "$pre_delete" = "true" ]; then
  echo "@@ Info: Deleting WebLogic domain '${DOMAIN_UID}' if it already exists and waiting for its pods to exit."
  if [ "$dry_run" = "false" ]; then
    kubectl -n ${DOMAIN_NAMESPACE} delete domain ${DOMAIN_UID} --ignore-not-found
    $SCRIPTDIR/util-wl-pod-wait.sh -p 0
  else
    echo dryrun: kubectl -n ${DOMAIN_NAMESPACE} delete domain ${DOMAIN_UID} --ignore-not-found
    echo dryrun: $SCRIPTDIR/util-wl-pod-wait.sh -p 0
  fi
fi

#
# Apply the domain resource.
#

echo "@@"
echo "@@ Info: Calling 'kubectl apply -f \$WORKDIR/mii-$DOMAIN_UID.yaml'."

if [ "$dry_run" = "false" ]; then
  kubectl apply -f $WORKDIR/mii-$DOMAIN_UID.yaml
else
  echo dryrun: kubectl apply -f $WORKDIR/mii-$DOMAIN_UID.yaml
fi

#
# We're done, but let's print out some help.
#

function get_kube_address() {
  # address of kubectl master DNS
  kubectl cluster-info | grep KubeDNS | sed 's;^.*//;;' | sed 's;:.*$;;'
}

function get_host_address() {
  # address of current machine
  echo $(hostname).$(dnsdomainname)
}

function get_sample_host() {
  # host that we're setting on each ingress for the domain
  tr [A-Z_] [a-z-] <<< ${DOMAIN_UID}.mii-sample.org
}

function get_exec_command() {
  # Echo a kubectl exec command that invoke's the sample application
  # using a 'curl' from the admin server pod.
  local cluster_name=cluster-1
  local cluster_service_name=${DOMAIN_UID}-cluster-${cluster_name}
  local cluster_service_name=$(tr [A-Z_] [a-z-] <<< $cluster_service_name)
  local admin_name=admin-server
  local admin_service_name=${DOMAIN_UID}-${admin_name}
  local admin_service_name=$(tr [A-Z_] [a-z-] <<< $admin_service_name)
  echo "kubectl exec -n $DOMAIN_NAMESPACE $admin_service_name -- bash -c \"curl -s -S -m 10 http://$cluster_service_name:8001/sample_war/index.jsp\""
}

function get_curl_command() {
  # Echo a curl command you can use to invoke the sample application
  # via the Traefik load balancer listening on port 30305.
  # The '$1' parm must be a DNS address suitable for accessing the port.
  echo "curl -s -S -m 10 -H 'host: $(get_sample_host)' http://$1:30305/sample_war/index.jsp"
}

cat << EOF
@@
@@ Info: Your Model in Image domain resource deployed!

   To wait until pods start and/or get their status:
      kubectl get pods -n ${DOMAIN_NAMESPACE} --watch 
       # (ctrl-c once all pods are running and ready)
             -or-
      'SCRIPTDIR/util-wl-pod-wait.sh -n $DOMAIN_NAMESPACE -d $DOMAIN_UID -p 3 -v'

   To get the domain status:
      'kubectl -n $DOMAIN_NAMESPACE get domain $DOMAIN_UID -o yaml'
             -or-
      'kubectl -n $DOMAIN_NAMESPACE describe domain $DOMAIN_UID'

   To invoke the sample's web app via 'kubectl exec':
      - The sample's admin server pod must be running.
      - The sample's cluster pods must be running and ready.
      - Run: '$(get_exec_command)'

   To invoke the sample's web app via the Traefik load balancer:
      - Traefik must be running, monitoring namespace '$DOMAIN_NAMESPACE',
        and listening on external port 30305.
      - Traefik ingresses must have been deployed 
        (see 'stage-and-create-ingresses.sh' helper script).
      - The sample's cluster pods must be running and ready.
      - Run one of:
         '$(get_curl_command $(get_host_address))'
                 - or -
         '$(get_curl_command $(get_kube_address))'

    NOTE! If the introspector job fails or you see unexpected issues, then
          see 'User Guide->Manage WebLogic Domains->Model in Image->Debugging'
          in the documentation."

@@
@@ Info: Done! Script '$(basename $0)' completed without errors.
@@
EOF
