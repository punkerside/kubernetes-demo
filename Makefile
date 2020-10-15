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
	@aws eks update-kubeconfig --name $(PROJECT)-$(ENV) --region $(AWS_REGION)

metrics-server:
	@kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.7/components.yaml

cluster-autoscaler:
	@export CLUSTER_NAME=$(PROJECT)-$(ENV) && envsubst < k8s/cluster-autoscaler-autodiscover.yaml | kubectl apply -f -
	@kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"

charts:
	@helm repo add grafana https://grafana.github.io/helm-charts
	@helm repo add loki https://grafana.github.io/loki/charts
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	@helm repo add stable https://kubernetes-charts.storage.googleapis.com/
	@helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
	@helm repo add traefik https://helm.traefik.io/traefik
	@kubectl create namespace monitoring

jaeger:
	@helm install -n monitoring jaeger jaegertracing/jaeger -f k8s/jaeger.yaml

prometheus:
	@helm install -n monitoring prometheus prometheus-community/prometheus -f k8s/prometheus.yaml

loki:
	@helm install -n monitoring loki loki/loki -f k8s/loki.yaml

fluent-bit:
	@helm install -n monitoring fluent-bit loki/fluent-bit --set=loki.serviceName=loki.monitoring.svc.cluster.local --set=loki.serviceScheme=http --set=loki.servicePort=3100 --version=0.3.0

hotrod:
	@kubectl apply -f k8s/hotrod.yaml

grafana:
	@helm install -n monitoring grafana grafana/grafana -f k8s/grafana.yaml

traefik:
	@helm install traefik traefik/traefik -f k8s/traefik.yaml
	@kubectl apply -f k8s/traefik-metrics.yaml

hotrod-ingress:
	@kubectl apply -f k8s/hotrod-ingressroute.yaml

destroy:
	@helm uninstall -n monitoring traefik
	@helm uninstall -n monitoring jaeger
	@helm uninstall -n monitoring prometheus
	@helm uninstall -n monitoring loki
	@helm uninstall -n monitoring fluent-bit
	@helm uninstall -n monitoring grafana

	@cd terraform/ && terraform init
	@export AWS_DEFAULT_REGION="$(AWS_REGION)" && \
	cd terraform/ && terraform destroy \
	  -var 'project=$(PROJECT)' \
	  -var 'env=$(ENV)' \
	-auto-approve
