PROJECT    = falcon
ENV        = k8s
AWS_REGION = us-east-1

cluster:
	@cd terraform/ && terraform init
	@export AWS_DEFAULT_REGION="$(AWS_REGION)" && \
	cd terraform/ && terraform apply \
	  -var 'project=$(PROJECT)' \
	  -var 'env=$(ENV)' \
	-auto-approve

destroy:
	@cd terraform/ && terraform init
	@export AWS_DEFAULT_REGION="$(AWS_REGION)" && \
	cd terraform/ && terraform destroy \
	  -var 'project=$(PROJECT)' \
	  -var 'env=$(ENV)' \
	-auto-approve

metrics-server:
	@kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.7/components.yaml

cluster-autoscaler:
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
	@kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"
	@kubectl -n kube-system set image deployment.apps/cluster-autoscaler cluster-autoscaler=us.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler:v1.17.3

charts:
	helm repo add influxdata https://helm.influxdata.com/
	helm repo add loki https://grafana.github.io/loki/charts
	helm repo add traefik https://helm.traefik.io/traefik

influxdb:
	@helm install influxdb influxdata/influxdb --set=persistence.enabled=true --set=persistence.size=50Gi

loki:
	@helm install loki loki/loki --set=persistence.enabled=true --set=persistence.size=50Gi

telegraf:
	@helm install telegraf influxdata/telegraf-ds --set=config.outputs.influxdb.url=http://foo.bar:8086

fluent-bit:
	@helm install fluent-bit loki/fluent-bit --set=loki.serviceName=logging.devops.sandboxs.net --set=loki.serviceScheme=http --set=loki.servicePort=80

grafana:
	@helm install grafana stable/grafana --set=persistence.enabled=true --set=persistence.size=20Gi

# ingress:
# 	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
# 	kubectl apply -f configs/service-l7.yaml 
# 	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/aws/patch-configmap-l7.yaml

# demo:
# 	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-controller.json
# 	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-service.json
# 	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-controller.json
# 	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-service.json
# 	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-controller.json
# 	kubectl apply -f guestbook/guestbook-service.yaml
# 	kubectl apply -f guestbook/guestbook-ingress.yaml

# clean:
# 	kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/aws/patch-configmap-l7.yaml
# 	kubectl delete -f configs/service-l7.yaml 
# 	kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
# 	make destroy
