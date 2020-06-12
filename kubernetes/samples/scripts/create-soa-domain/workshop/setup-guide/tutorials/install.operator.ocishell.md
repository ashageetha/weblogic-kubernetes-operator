# Oracle WebLogic Server Kubernetes Operator Tutorial #

### Install and configure the operator  ###

An operator is an application-specific controller that extends Kubernetes to create, configure, and manage instances of complex applications. The Oracle WebLogic Server Kubernetes Operator (the "operator") simplifies the management and operation of WebLogic domains and deployments.

#### Clone the operator repository to a Cloud Shell instance ####
First, clone the operator git repository to OCI Cloud Shell.
```bash
$ git clone https://github.com/ashageetha/weblogic-kubernetes-operator.git -b soa_2.5.0_12.2.1.4
```
The output should be similar to the following:
```bash
Cloning into 'weblogic-kubernetes-operator'...
remote: Enumerating objects: 18, done.
remote: Counting objects: 100% (18/18), done.
remote: Compressing objects: 100% (17/17), done.
remote: Total 137218 (delta 1), reused 12 (delta 1), pack-reused 137200
Receiving objects: 100% (137218/137218), 102.44 MiB | 27.30 MiB/s, done.
Resolving deltas: 100% (81773/81773), done.
Checking out files: 100% (8398/8398), done.
```
#### Prepare the environment ####
Kubernetes distinguishes between the concept of a user account and a service account for a number of reasons. The main reason is that user accounts are for humans while service accounts are for processes, which run in pods. The operator also requires service accounts.  If a service account is not specified, it defaults to `default` (for example, the namespace's default service account). If you want to use a different service account, then you must create the operator's namespace and the service account before installing the operator Helm chart.

Thus, create the operator's namespace in advance:
```bash
kubectl create namespace opns
```
Create the service account:
```bash
kubectl create serviceaccount -n opns op-sa
```
Finally, add a stable repository to Helm, which will be needed later for 3rd party services.
```bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
```
#### Install the operator using Helm ####
Before you execute the operator `helm` install, make sure that you are in the operator's local Git repository folder.
```bash
cd ~/weblogic-kubernetes-operator/
```
Use the `helm install` command to install the operator Helm chart. As part of this, you must specify a "release" name for their operator.

You can override the default configuration values in the operator Helm chart by doing one of the following:

- Creating a [custom YAML](https://github.com/oracle/weblogic-kubernetes-operator/blob/v2.5.0/kubernetes/charts/weblogic-operator/values.yaml) file containing the values to be overridden, and specifying the `--value` option on the Helm command line.
- Overriding individual values directly on the Helm command line, using the `--set` option.

Using the last option, simply define overriding values using the `--set` option.

Note the values:

- **name**: The name of the resource.
- **namespace**: Where the operator is deployed.
- **image**: The prebuilt operator 2.5.0 image, available on the public Docker hub.
- **serviceAccount**: The service account required to run the operator.
- **domainNamespaces**: The namespaces where WebLogic domains are deployed in order to control them. Note, the WebLogic domain is not deployed yet, so this value will be updated when namespaces are created for WebLogic deployment.

Execute the following `helm install`:
```bash
helm install weblogic-kubernetes-operator \
  kubernetes/charts/weblogic-operator \
  --namespace opns \
  --set image=oracle/weblogic-kubernetes-operator:2.5.0 \
  --set serviceAccount=op-sa \
  --set "domainNamespaces={}" \
  --wait
```
The output will be similar to the following:
```bash
NAME: weblogic-kubernetes-operator
LAST DEPLOYED: Mon Jun  1 10:46:24 2020
NAMESPACE: opns
STATUS: deployed
REVISION: 1
TEST SUITE: None
```
Check the operator pod:
```bash
$ kubectl get pods -n opns
NAME                                 READY   STATUS    RESTARTS   AGE
weblogic-operator-8688fb44b7-c4qk9   1/1     Running   0          5m25s
```
Check the operator Helm chart:
```bash
$ helm list -n opns
NAME                            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
weblogic-kubernetes-operator    opns            1               2020-06-01 10:46:24.821204106 +0000 UTC deployed        weblogic-operator-2.5.0
```

The WebLogic Server Kubernetes Operator v2.5.0 has been installed. You can continue with SOA domain Setup.
