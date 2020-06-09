## Get the source code
cd ~/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-soa-domain/workshop/webhook

## Create webhook image
Run:

`./create_webhook_image.sh webhook:2.0`

Default, without any image details it creates webhook:1.0 docker image


## Deploy webhook HTTP Server ( update the image details - default is webhook:1.0)
Execute:

`kubectl apply -f webhook.yaml`

## Webhook is available at:
`http://webhook.default.svc.cluster-local:8080/webhook`
