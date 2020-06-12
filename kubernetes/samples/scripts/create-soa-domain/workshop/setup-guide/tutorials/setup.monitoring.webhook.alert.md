# Create Oracle Container Engine for Kubernetes (OKE) on Oracle Cloud Infrastructure (OCI) #
 
Setup Webhook and Alerts

Use the following instructions to create a webhook

   a. Browse to the webhook  project provided in reporsitory
   ```bash
   $ cd ~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-soa-domain/workshop/webhook
   ```
   
   b. Build the webhook image "webhook:1.0". The webhook is written in golang  which logs all the received notifications. Typically, this webhook receivers is used to notify systems that Alertmanager doesn’t support directly.
   ```bash
   $ ./create_webhook_image.sh [IMAGE]
   ```
   
   c. Push the http hook image into OCIR
   ```bash
   $ docker tag webhook:1.0 phx.ocir.io/tenancy-foo/webhook:1.0
   $ docker push phx.ocir.io/tenancy-foo/webhook:1.0
   ```
   d. Create the imagePullSecrets (in default namespace) so that Kubernetes Deployment can pull the image automatically from OCIR with below command :
   Note: Create the imagePullSecret as per your environement
   ```bash
   $ kubectl create secret docker-registry image-secret --docker-server=phx.ocir.io  --docker-username=tenancy-foo/me@oracle.com --docker-password='bxnXvug9A2vvnI(;fczF'  --docker-email=me@oracle.com
   ```
   e. Deploy the webhook into the OKE Cluster:
   ```bash
   $ kubectl apply -f webhook.yaml
   ```
   f. webhook is available at:
    Webhook is available at : http://webhook.default.svc.cluster.local:8080/webhook
   
Configure Alert

    a. Below is sample custom rule provided in the repository
	```bash
	apiVersion: monitoring.coreos.com/v1
	kind: PrometheusRule
	metadata:
	labels:
		prometheus: k8s
		role: alert-rules
	name: prometheus-k8s-rules-custom
	namespace: monitoring
	spec:
	groups:
	- name: custom-rules
		rules:
		- alert: ClusterWarning
		  expr: sum by (weblogic_domainUID,weblogic_clusterName)  (up{weblogic_domainUID=~".+",weblogic_serverName!="AdminServer"}) == 1
		  for: 1m
		  labels:
			 severity: page
		  annotations:
			 summary: "Some WLS Cluster has only one running server for more than 1 minute"
		     description: "Some WLS Cluster is in Warning State"
	```
	
	b. Deploy the custom rule to monitoring namespace
	```bash
	$ cd ~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-soa-domain/workshop/webhook
	$ kubectl apply -f prometheus-k8s-rules-custom.yaml
	```
	
	c. Once the new rule is deployed into the current monitoring system, verify if the new rules gets listed in Prometheus as shown below at
       Web UI : http://${TRAEFIK_PUBLIC_IP}/prometheus/rules

    []

Update the Alertmanager with webhook details
	a. Get the alertmanager.yaml which is stored in as secret in alertmanager-main
	```bash
	$ kubectl -n monitoring get secret alertmanager-main -ojson | jq -r '.data["alertmanager.yaml"]'| base64 -d > alertmanager.yaml.orig
	```
	
	b. Modify the yaml to add the webhook details. 
	Sample updated alertmanager.yaml as shown below is provided in the repository and available at " weblogic-kubernetes-operator/kubernetes/samples/scripts/create-soa-domain/workshop/webhook"
	```yaml
	$ cat alertmanager.yaml
	"global":
	"resolve_timeout": "5m"
	"receivers":
	- "name": "null"
	- "name": "webhook"
	"webhook_configs":
	- "send_resolved": true
		"http_config": {}
		"url": "http://webhook.default.svc.cluster.local:8080/webhook"
	"route":
	"receiver": "null"
	"group_by":
	- "alertname"
	"group_interval": "10s"
	"group_wait": "10s"
	"repeat_interval": "1h"
	"routes":
	- "match":
		"alertname": "ClusterWarning"
		"receiver": "webhook"
	```
	```bash
	$ cd ~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-soa-domain/workshop/webhook
	$ kubectl -n monitoring create secret generic alertmanager-main --from-literal=alertmanager.yaml="$(< alertmanager.yaml)" --dry-run -oyaml | kubectl -n monitoring replace secret --filename=-
	```
	c. Login to Alertmanager web UI ( http://${TRAEFIK_PUBLIC_IP}/alertmanager/#status) and verify if the webhook URL is reflected into the config at status:
	Note: If you don't see the updated config, refresh for sometimes. It takes a couple of seconds to get refreshed with the updated config
	[]
	

Triggering Alerts
	
Since our SOA and OSB cluster both are configured with one server each, we can see that the "ClusterWarning" alert will be fired for both clusters.
Navigate to Prometheus UI http://${TRAEFIK_PUBLIC_IP}/prometheus/alerts and you can see the State of "ClusterWarning" Alert as FIRING as shown below:
[]


Verify that triggered Alerts are seen on Alertmanager at Alerts Page:
Navigate the Alertmanage UI: http://${TRAEFIK_PUBLIC_IP}/alertmanager/#/alerts?silenced=false&inhibited=false&active=true&filter=%7Balertname%3D"ClusterWarning"%7D
[]

Vertification in webhook pod on Alert details:
```bash
$ kubectl logs webhook-7b8bf5b9b4-tvktn  -f --tail=8
```
Output will be as below
```bash
2020/06/12 16:21:28 POST /webhook HTTP/1.1
Host: webhook.default.svc.cluster.local:8080
Content-Length: 1792
Content-Type: application/json
User-Agent: Alertmanager/0.18.0

{"receiver":"webhook","status":"firing","alerts":[{"status":"firing","labels":{"alertname":"ClusterWarning","prometheus":"monitoring/k8s","severity":"page","weblogic_clusterName":"osb_cluster","weblogic_domainUID":"soainfra"},"annotations":{"description":"Some WLS Cluster is in Warning State","summary":"Some WLS Cluster has only one running server for more than 1 minute"},"startsAt":"2020-06-10T14:45:50.760376266Z","endsAt":"0001-01-01T00:00:00Z","generatorURL":"http://129.146.227.145/prometheus/graph?g0.expr=sum+by%28weblogic_domainUID%2C+weblogic_clusterName%29+%28up%7Bweblogic_domainUID%3D~%22.%2B%22%2Cweblogic_serverName%21%3D%22AdminServer%22%7D%29+%3D%3D+1\u0026g0.tab=1"},{"status":"firing","labels":{"alertname":"ClusterWarning","prometheus":"monitoring/k8s","severity":"page","weblogic_clusterName":"soa_cluster","weblogic_domainUID":"soainfra"},"annotations":{"description":"Some WLS Cluster is in Warning State","summary":"Some WLS Cluster has only one running server for more than 1 minute"},"startsAt":"2020-06-12T16:21:20.760376266Z","endsAt":"0001-01-01T00:00:00Z","generatorURL":"http://129.146.227.145/prometheus/graph?g0.expr=sum+by%28weblogic_domainUID%2C+weblogic_clusterName%29+%28up%7Bweblogic_domainUID%3D~%22.%2B%22%2Cweblogic_serverName%21%3D%22AdminServer%22%7D%29+%3D%3D+1\u0026g0.tab=1"}],"groupLabels":{"alertname":"ClusterWarning"},"commonLabels":{"alertname":"ClusterWarning","prometheus":"monitoring/k8s","severity":"page","weblogic_domainUID":"soainfra"},"commonAnnotations":{"description":"Some WLS Cluster is in Warning State","summary":"Some WLS Cluster has only one running server for more than 1 minute"},"externalURL":"http://alertmanager-main-2:9093","version":"4","groupKey":"{}/{alertname=\"ClusterWarning\"}:{alertname=\"ClusterWarning\"}"}
```