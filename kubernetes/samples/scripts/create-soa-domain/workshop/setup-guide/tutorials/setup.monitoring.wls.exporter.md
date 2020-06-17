# Create Oracle Container Engine for Kubernetes (OKE) on Oracle Cloud Infrastructure (OCI) #


Install Prometheus to monitor Kubernetes and applications running on Kubernetes 

a. Get the kube-prometheus project which supports Kubernetes Version 1.15.7
```bash
$ wget https://github.com/coreos/kube-prometheus/archive/v0.3.0.zip
$ unzip v0.3.0.zip
```

b. You can create separate traefik-operator to handle the Monitoring Services in monitoring namespace. Here we will reuse ${TRAEFIK_PUBLIC_IP} to access monitoring system ( Prometheus, Alertmanager and Grafana). Hence configure traefik-operator to manage in "monitoring" namespace with below command
```bash
$ cd ~/weblogic-kubernetes-operator/kubernetes/samples/charts
$ helm upgrade --reuse-values --set "kubernetes.namespaces={traefik,soans,monitoring}" --wait traefik-operator stable/traefik --namespace traefik
```

c. Update 'prometheus-prometheus.yaml'  to add the externalURL, as in the upcoming steps we will be creating the ingress rules for prometheus to be available at /prometheus
Note: This step may vary based on the ingress rules created
```bash
$ cd ~/kube-prometheus-0.3.0/manifests
$ sed -i -e "s:replicas\: 2:replicas\: 2\\n  externalUrl\: http\://${TRAEFIK_PUBLIC_IP}/prometheus:g" prometheus-prometheus.yaml
```

d. Create the kube-prometheus resources
Change to the kube-prometheus directory and execute the following commands to create the namespace and CRDs.
Wait for their availability before creating the remaining resources.
```bash
$ cd ~/kube-prometheus-0.3.0
$ kubectl create -f manifests/setup
$ until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
$ kubectl create -f manifests/
```

Setup Ingress for external access through "${TRAEFIK_PUBLIC_IP}". Create the below ingress for monitoring namespace which is already provided in the repository
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: monitoring-ingress
  namespace: monitoring
  annotations:
    ingress.kubernetes.io/rewrite-target: "/"
spec:
  rules:
  - http:
      paths:
      - backend:
          serviceName: prometheus-k8s
          servicePort: 9090
        path: /prometheus
      - backend:
          serviceName: alertmanager-main
          servicePort: 9093
        path: /alertmanager
      - backend:
          serviceName: grafana
          servicePort: http
```

```bash
$ cd ~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-soa-domain/workshop/ingress-samples
$ kubectl apply -f monitoring-ingress.yaml
```

Grafana, Prometheus, and Alertmanager will be accessible at below  paths
```bash
Prometheus     : http://${TRAEFIK_PUBLIC_IP}/prometheus
Alertmanagaer  : http://${TRAEFIK_PUBLIC_IP}/alertmanager
Grafana        : http://${TRAEFIK_PUBLIC_IP}/login
```

Setup WebLogic Monitoring Exporter

Use the following instructions to set up the WebLogic Monitoring Exporter to collect WebLogic Server metrics and monitor a SOA domain.

Currently the required wls-exporter.<admin/soa/osb>.war are already created and provided for you to deploy into your Domain and available at "~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-soa-domain/workshop/wls-exporter-deploy".
Below steps provides details on how to create the the wls-exporter.war based on your configuration file.
*Note*: Need not execute the below steps a, b and c as its already executed and updates war's are provided in repository.

	a. Download the getX.X.X.sh  from the Releases[link] page.
	```bash
	$ mkdir wls_monitoring_exporter
	$ cd wls_monitoring_exporter
	$ wget https://github.com/oracle/weblogic-monitoring-exporter/releases/download/v1.1.2/get1.1.2.sh
	$ chmod +x get1.1.2.sh
	```
	
	b. Create a configuration files (for 7001, 8001 and 9001) for the WebLogic Monitoring Exporter
	The configuration file will have the server port of the WebLogic Server instance where the monitoring exporter application will be deployed.
	See the following sample snippet of the configuration for AdminServer with 7001 (config-admin.yaml) 
	```yaml
	metricsNameSnakeCase: true
	restPort: 7001
	queries:
	- key: name
	  keyName: location
	  prefix: wls_server_
	  applicationRuntimes:
       key: name
       keyName: app
       componentRuntimes:
          prefix: wls_webapp_config_
          type: WebAppComponentRuntime
          key: name
          values: [deploymentState, contextRoot, sourceInfo, openSessionsHighCount, openSessionsCurrentCount, sessionsOpenedTotalCount, sessionCookieMaxAgeSecs, sessionInvalidationIntervalSecs, sessionTimeoutSecs, singleThreadedServletPoolSize, sessionIDLength, servletReloadCheckSecs, jSPPageCheckSecs]
          servlets:
            prefix: wls_servlet_
            key: servletName

    - JVMRuntime:
        prefix: wls_jvm_
        key: name

    - executeQueueRuntimes:
        prefix: wls_socketmuxer_
        key: name
        values: [pendingRequestCurrentCount]

    - workManagerRuntimes:
        prefix: wls_workmanager_
        key: name
        values: [stuckThreadCount, pendingRequests, completedRequests]

    - threadPoolRuntime:
        prefix: wls_threadpool_
        key: name
        values: [executeThreadTotalCount, queueLength, stuckThreadCount, hoggingThreadCount]

    - JMSRuntime:
        key: name
        keyName: jmsruntime
        prefix: wls_jmsruntime_
        JMSServers:
          prefix: wls_jms_
          key: name
          keyName: jmsserver
          destinations:
             prefix: wls_jms_dest_
             key: name
             keyName: destination

    - persistentStoreRuntimes:
        prefix: wls_persistentstore_
        key: name
    - JDBCServiceRuntime:
        JDBCDataSourceRuntimeMBeans:
          prefix: wls_datasource_
          key: name
    - JTARuntime:
        prefix: wls_jta_
        key: name
	```
	
	c. Generate the deployment package for AdminServer ( with restPort as 7001), soa_cluster ( with restPort as 8001) and osb_cluster ( with restPort as 9001). See the following sample usage with config-admin.yaml which pulls the wls-exporter.war and updates the config.yml with details from config-admin.yaml
	```bash
	$ ./get1.1.2.sh config-admin.yaml
	% Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
	100   629  100   629    0     0   1404      0 --:--:-- --:--:-- --:--:--  1407
	100 2018k  100 2018k    0     0  1876k      0  0:00:01  0:00:01 --:--:-- 3578k
	created /tmp/ci-ZOBtppuCUv
	/tmp/ci-ZOBtppuCUv ~/wls_monitoring_exporter
	in temp dir
	updating: config.yml
			zip warning: Local Entry CRC does not match CD: config.yml
	(deflated 63%)
	~/wls_monitoring_exporter
    ```

Deploy the WebLogic Monitoring Exporter into AdminServer, soa_cluster and osb_cluster.
Samples are provided in the repository to deploy wls-exporter.war into all servers in the Cluster. 
Follow below steps:
```bash
$ cd ~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-soa-domain/workshop
$ kubectl cp wls-exporter-deploy soans/soainfra-adminserver:/u01/oracle
$ kubectl exec -it -n soans soainfra-adminserver -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/wls-exporter-deploy/deploy-wls-exporter-soa-domain.py
```

Prometheus Operator configuration

You must configure Prometheus to collect the metrics from the WebLogic Monitoring Exporter. The Prometheus Operator identifies the targets using service discovery. To get the WebLogic Monitoring Exporter end point discovered as a target, you must create a service monitor pointing to the service.

Sample service monitor deployment YAML  configuration file for AdminServer, soa_cluster and osb_cluster is available at "~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-soa-domain/workshop/wls-exporter-access/wls-exporter-ServiceMonitor.yaml".

You need to add RoleBinding and Role for the namespace (soans) under which the WebLogic Servers pods are running in the Kubernetes cluster. These are required for Prometheus to access the endpoints provided by the WebLogic Monitoring Exporters.   Sample YAML configuration files,  prometheus-roleBindingsoans.yaml and prometheus-roleSpecificsoans.yaml for soans are provided in "~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-soa-domain/workshop/wls-exporter-access".

Perform the below steps so Prometheus is able to collect the metrics from the WebLogic Monitoring Exporter.
```bash
$ cd ~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-soa-domain/workshop/wls-exporter-access
$ kubectl apply -f .
```

Verify that Prometheus is able to discover these Services and collect the metrics
*Navigate* : Login http://${TRAEFIK_PUBLIC_IP}/prometheus -> Status to see the Service Discovery details as shown below
[]


Grafana dashboard - Deploy the  provided in the WebLogic Monitoring Exporter to view the domain metrics with below steps:

    a. Navigate: Login to Grafana http://${TRAEFIK_PUBLIC_IP}/login ->  + (Create) -> Import -> Upload .json file -> Then upload the attached  WebLogic Server Dashboard.json
	[]
	
	b. WebLogic Server Dashboard shows below details:
	[]
