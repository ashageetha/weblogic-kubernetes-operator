# Oracle WebLogic Server Kubernetes Operator Tutorial #

### Install and configure Traefik  ###

The Oracle WebLogic Server Kubernetes Operator supports three load balancers: Traefik, Voyager, and Apache. Samples are provided in the [documentation](https://github.com/oracle/weblogic-kubernetes-operator/blob/v2.5.0/kubernetes/samples/charts/README.md).

This tutorial demonstrates how to install the [Traefik](https://traefik.io/) Ingress controller to provide load balancing for WebLogic clusters.

#### Install the Traefik operator with a Helm chart ####

Change to your operator local Git repository folder.
```bash
cd ~/weblogic-kubernetes-operator/
```
Create a namespace for Traefik:
```bash
kubectl create namespace traefik
```
Install the Traefik operator in the `traefik` namespace with the provided sample values:
```bash
helm install traefik-operator \
stable/traefik \
--namespace traefik \
--values kubernetes/samples/charts/traefik/values.yaml  \
--set "kubernetes.namespaces={traefik}" \
--set "serviceType=LoadBalancer"
```

The output should be similar to the following:
```bash
NAME: traefik-operator
LAST DEPLOYED: Mon Jun  1 19:31:20 2020
NAMESPACE: traefik
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Get Traefik's load balancer IP/hostname:
 
     NOTE: It may take a few minutes for this to become available.
 
     You can watch the status by running:
 
         $ kubectl get svc traefik-operator --namespace traefik -w
 
     Once 'EXTERNAL-IP' is no longer '<pending>':
 
         $ kubectl describe svc traefik-operator --namespace traefik | grep Ingress | awk '{print $3}'
 
2. Configure DNS records corresponding to Kubernetes ingress resources to point to the load balancer IP/hostname found in step 1
```

The Traefik installation is basically done. Verify the Traefik (load balancer) services:
```bash
kubectl get service -n traefik
NAME                         TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)                      AGE
traefik-operator             LoadBalancer   10.96.252.109   129.146.227.145   443:31596/TCP,80:31943/TCP   23h
traefik-operator-dashboard   ClusterIP      10.96.110.22    <none>            80/TCP                       23h
```
Please note the EXTERNAL-IP of the *traefik-operator* service. This is the public IP address of the load balancer that you will use to access the WebLogic Server Administration Console and the SOA applications.

To print only the public IP address, execute this command:
```bash
$ TRAEFIK_PUBLIC_IP=`kubectl describe svc traefik-operator --namespace traefik | grep Ingress | awk '{print $3}'`
$ echo $TRAEFIK_PUBLIC_IP
129.146.227.14
```

Verify the `helm` charts:
```bash
$ helm list -n traefik
NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
traefik-operator        traefik         2               2020-06-01 19:54:21.330962779 +0000 UTC deployed        traefik-1.87.0  1.7.2 
```
You can also access the Traefik dashboard using `curl`. Use the `EXTERNAL-IP` address from the result above:

    curl -H 'host: traefik.example.com' http://${TRAEFIK_PUBLIC_IP}

For example:

    $ curl -H 'host: traefik.example.com' http://${TRAEFIK_PUBLIC_IP}
    <a href="/dashboard/">Found</a>.
