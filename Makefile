PROJECT    = falcon
ENV        = k8s
AWS_REGION = us-east-1

cluster:
<<<<<<< HEAD
	cd terraform/ && terraform init
<<<<<<< HEAD

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD

# # creando cluster kubernetes
# create:
# 	@eksctl create cluster \
# 	  --name $(OWNER)-$(ENV) \
# 	  --region $(AWS_REGION) \
# 	  --version $(NODE_VER) \
# 	  --node-type $(NODE_TYPE) \
# 	  --vpc-private-subnets $(AWS_PRI) \
# 	  --vpc-public-subnets $(AWS_PUB) \
# 	  --asg-access \
# 	  --nodes $(NODE_DES) \
# 	  --nodes-min $(NODE_MIN) \
# 	  --nodes-max $(NODE_MAX) \
# 	  --ssh-access=true \
# 	  --auto-kubeconfig

create:
	export \
	  NAME=$(OWNER)-$(ENV) \
	  AWS_REGION=$(AWS_REGION) \
	&& envsubst < k8s/cluster.yaml | eksctl create cluster -f -


# instalando complemento dashboard
addon-dashboard:
	@kubectl --kubeconfig=$(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml
	@kubectl --kubeconfig=$(KUBECONFIG) apply -f k8s/eks-admin-service-account.yaml
	@echo ""
	@kubectl -n kube-system describe secret $$(kubectl -n kube-system get secret | grep eks-admin | awk '{print $$1}') | grep "token:"
	@echo ""

# instalando complemento de metricas para pods
addon-metrics:
	@mkdir -p tmp/ && rm -rf tmp/metrics-server/ && cd tmp/ && git clone https://github.com/kubernetes-incubator/metrics-server.git
	@kubectl --kubeconfig=$(KUBECONFIG) apply -f tmp/metrics-server/deploy/1.8+/

# instalando nginx ingress controller 
addon-ingress:
	@kubectl --kubeconfig=$(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
	@kubectl --kubeconfig=$(KUBECONFIG) apply -f k8s/service-l7.yaml
	@kubectl --kubeconfig=$(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/aws/patch-configmap-l7.yaml

# instalando complemento cluster autoscaler
addon-autoscaler:
	$(eval AWS_AUTOSCALING_GROUP = $(shell aws --region $(AWS_REGION) autoscaling describe-auto-scaling-groups | grep $(OWNER)-$(ENV) | grep AutoScalingGroupName | cut -d '"' -f 4))
	@export AWS_AUTOSCALING_GROUP=$(AWS_AUTOSCALING_GROUP) && envsubst < k8s/cluster-autoscaler-autodiscover.yaml | kubectl --kubeconfig=$(KUBECONFIG) apply -f -

# desplegando guestbook
deploy-guestbook:
	@kubectl --kubeconfig=$(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-controller.json
	@kubectl --kubeconfig=$(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-service.json
	@kubectl --kubeconfig=$(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-controller.json
	@kubectl --kubeconfig=$(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-service.json
	@kubectl --kubeconfig=$(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-controller.json
	@kubectl --kubeconfig=$(KUBECONFIG) apply -f guestbook/service.json
	@kubectl --kubeconfig=$(KUBECONFIG) apply -f guestbook/ingress.yaml
	@echo "" && echo "Configurar archivo hosts" && echo ""
	@sh k8s/getip.sh $(OWNER) $(ENV) $(AWS_REGION) && echo ""
=======
# creando cluster kubernetes
=======
>>>>>>> 702ac8a (agregando terraform para la creacion de dns)
create:
<<<<<<< HEAD
	eksctl create cluster \
	  --name $(OWNER)-$(ENV) \
	  --region $(AWS_REGION) \
	  --version $(KUBE_VER) \
	  --node-type $(NODE_TYPE) \
	  --zones "$(AWS_ZONES)" \
	  --nodes-min $(NODE_MIN) \
	  --nodes-max $(NODE_MAX) \
	  --asg-access \
	  --auto-kubeconfig
<<<<<<< HEAD
<<<<<<< HEAD
	cat $(HOME)/.kube/config > $(HOME)/.kube/config.save && rm -rf $(HOME)/.kube/config
	ln -s $(HOME)/.kube/eksctl/clusters/$(OWNER)-$(ENV) $(HOME)/.kube/config
>>>>>>> 56d23e3 (fix stress)
=======
	@cat $(HOME)/.kube/config > $(HOME)/.kube/config.save && rm -rf $(HOME)/.kube/config
	@ln -s $(HOME)/.kube/eksctl/clusters/$(OWNER)-$(ENV) $(HOME)/.kube/config
>>>>>>> e029d55 (fix readme)
=======
>>>>>>> 38e6e34 (fix default)
=======
	export \
	  NAME=$(OWNER)-$(ENV) \
	  AWS_REGION=$(AWS_REGION) \
	  AWS_ZONES=$(AWS_ZONES) \
	  KUBE_VER=$(KUBE_VER) \
	  NODE_TYPE=$(NODE_TYPE) \
	  NODE_MIN=$(NODE_MIN) \
	  NODE_MAX=$(NODE_MAX) \
	&& envsubst < k8s/cluster.yaml | eksctl create cluster --auto-kubeconfig -f -
>>>>>>> 1a914d3 (varios cambios)
=======
apply:
=======
>>>>>>> 248bfd3 (fix travisci)
=======
	@cd terraform/ && terraform init
	@export AWS_DEFAULT_REGION="$(AWS_REGION)" && \
>>>>>>> 8a07b68 (agregando modulo eks y multiples cambios)
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

hotrod:
	@kubectl apply -f k8s/hotrod.yaml

prometheus:
	@helm install -n monitoring prometheus prometheus-community/prometheus -f k8s/prometheus.yaml

loki:
	@helm install -n monitoring loki loki/loki -f k8s/loki.yaml

fluent-bit:
	@helm install -n monitoring fluent-bit loki/fluent-bit --set=loki.serviceName=loki.monitoring.svc.cluster.local --set=loki.serviceScheme=http --set=loki.servicePort=3100 --version=0.3.0

grafana:
	@helm install -n monitoring grafana grafana/grafana -f k8s/grafana.yaml

traefik:
	@helm install traefik traefik/traefik -f k8s/traefik.yaml
	@kubectl apply -f k8s/traefik-metrics.yaml

hotrod-ingress:
	@kubectl apply -f k8s/hotrod-ingressroute.yaml

destroy:
	@helm uninstall traefik
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
<<<<<<< HEAD

<<<<<<< HEAD
<<<<<<< HEAD
destroy:
	cd terraform/ && terraform destroy \
	  -var 'region=$(AWS_REGION)' \
	  -var 'profile=$(AWS_PROFILE)' \
	  -var 'domain=$(DOMAIN)' \
	  -var 'project=$(PROJECT)' \
	  -var 'env=$(ENV)' \
	  -var 'cidr_vpc=$(CIDR_VPC)' \
	  -var 'cidr_pri=$(CIDR_PRI)' \
	  -var 'cidr_pub=$(CIDR_PUB)' \
	  -var 'instance_types=$(K8S_NODE_TYPE)' \
	  -var 'desired_capacity=$(K8S_NODE_SIZE)' \
	  -var 'min_size=$(K8S_NODE_MINI)' \
	  -var 'max_size=$(K8S_NODE_MAXI)' \
	  -var 'eks_version=$(K8S_CLUS_VERS)' \
	  -var 'on_demand_percentage_above_base_capacity=$(K8S_NODE_SPOT)'
>>>>>>> 032725f (agregando terraform, cambios de ingress, cambio de version de kubernetes)

=======
>>>>>>> 6bd70c4 (fix travisci)
metrics:
	$(eval DOWNLOAD_URL = $(shell curl -Ls "https://api.github.com/repos/kubernetes-sigs/metrics-server/releases/latest" | jq -r .tarball_url))
	$(eval DOWNLOAD_VERSION = $(shell grep -o '[^/v]*$$' <<< $(DOWNLOAD_URL)))
	@kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v$(DOWNLOAD_VERSION)/components.yaml
=======
metrics-server:
	@kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.7/components.yaml
>>>>>>> 8a07b68 (agregando modulo eks y multiples cambios)

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

<<<<<<< HEAD
prometheus:
	helm install prometheus stable/prometheus \
	  --namespace $(K8S_NAMESPACE) \
	  --set alertmanager.enabled=false,pushgateway.enabled=false,server.persistentVolume.storageClass="gp2",server.ingress.enabled="false"

grafana:
	helm install grafana stable/grafana \
	  -f configs/grafana.yml \
	  --namespace $(K8S_NAMESPACE) \
	  --set=ingress.enabled=false

<<<<<<< HEAD
# desplegando guestbook
deploy-guestbook:
	@kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-controller.json
	@kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-service.json
	@kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-controller.json
	@kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-service.json
	@kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-controller.json
	@kubectl --kubeconfig $(KUBECONFIG) apply -f guestbook/service.json
	@kubectl --kubeconfig $(KUBECONFIG) apply -f guestbook/ingress.yaml
=======
elasticsearch:
	helm install elasticsearch elastic/elasticsearch --namespace $(K8S_NAMESPACE) \
	  --set persistence.enabled="false",replicas=2
=======
telegraf:
	@helm install telegraf influxdata/telegraf-ds --set=config.outputs.influxdb.url=http://foo.bar:8086
>>>>>>> e440ee1 (agregando modulo eks y multiples cambios)

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

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
dns:
<<<<<<< HEAD
<<<<<<< HEAD
	$(eval ZONE_ID = $(shell aws route53 list-hosted-zones-by-name --dns-name punkerside.com | grep hostedzone  | cut -d'/' -f3 | cut -d'"' -f1))
	@mkdir -p scripts/dns/tmp/
	@cp scripts/dns/grafana.json scripts/dns/tmp/grafana.json
	@cp scripts/dns/kibana.json scripts/dns/tmp/kibana.json
	@cp scripts/dns/guestbook.json scripts/dns/tmp/guestbook.json
	@sed -i 's/ALB_ZONE/$(ALB_ZONE)/g' scripts/dns/tmp/kibana.json
	@sed -i 's/ALB_ZONE/$(ALB_ZONE)/g' scripts/dns/tmp/grafana.json
	@sed -i 's/ALB_ZONE/$(ALB_ZONE)/g' scripts/dns/tmp/guestbook.json
	@sed -i 's/ALB_DNS/$(ALB_DNS)/g' scripts/dns/tmp/kibana.json
	@sed -i 's/ALB_DNS/$(ALB_DNS)/g' scripts/dns/tmp/grafana.json
	@sed -i 's/ALB_DNS/$(ALB_DNS)/g' scripts/dns/tmp/guestbook.json
	aws route53 change-resource-record-sets --hosted-zone-id $(ZONE_ID) --change-batch file://scripts/dns/tmp/grafana.json
	aws route53 change-resource-record-sets --hosted-zone-id $(ZONE_ID) --change-batch file://scripts/dns/tmp/kibana.json
	aws route53 change-resource-record-sets --hosted-zone-id $(ZONE_ID) --change-batch file://scripts/dns/tmp/guestbook.json
>>>>>>> 8ababbf (corrigiendo errores)
=======
	$(eval LB_DNS = $(shell kubectl get services -o wide --all-namespaces | grep ingress-nginx | awk '{print $$5}'))
	$(eval LB_IP = $(shell dig +short $(LB_DNS) | head -1))
	@echo "$(LB_IP)	prometheus.$(DOMAIN) grafana.$(DOMAIN) kibana.$(DOMAIN) guestbook.$(DOMAIN)"
>>>>>>> 067f3c0 (modificando documentacion y corrigiendo procesos automatizados)
=======
ifeq ($(DNS_OWNER), true)
	cd terraform/ && terraform init
	export AWS_DEFAULT_REGION=$(AWS_REGION) && cd terraform/ && terraform apply \
	  -var 'dns_name=$(ELB_DNS)' \
	  -var 'zone_id=$(ELB_ZONE)' \
	  -var 'domain=$(DOMAIN)' \
	-auto-approve
endif
ifeq ($(DNS_OWNER), false)
	@echo "$(ELB_IP)	prometheus.$(DOMAIN) grafana.$(DOMAIN) kibana.$(DOMAIN) guestbook.$(DOMAIN)"
endif
<<<<<<< HEAD
>>>>>>> 31e81a3 (agregando terraform para la creacion de dns)
=======
>>>>>>> 8008a92 (correciones dns y modificar servicios helm)
=======
# dns:
# ifeq ($(DNS_OWNER), true)
# 	cd terraform/ && terraform init
# 	export AWS_DEFAULT_REGION=$(AWS_REGION) && cd terraform/ && terraform apply \
# 	  -var 'dns_name=$(ELB_DNS)' \
# 	  -var 'zone_id=$(ELB_ZONE)' \
# 	  -var 'domain=$(DOMAIN)' \
# 	-auto-approve
# endif
# ifeq ($(DNS_OWNER), false)
# 	@echo "$(ELB_IP)	prometheus.$(DOMAIN) grafana.$(DOMAIN) kibana.$(DOMAIN) guestbook.$(DOMAIN)"
# endif
>>>>>>> 5045ef6 (agregando terraform, cambios de ingress, cambio de version de kubernetes)
=======
dns:
	$(eval LB_NAME = $(shell sh configs/dns.sh $(AWS_REGION) $(PROJECT)-$(ENV)))
	cd terraform/dns/ && terraform init
	cd terraform/dns/ && terraform apply \
	  -var 'region=$(AWS_REGION)' \
	  -var 'domain=$(DOMAIN)' \
	  -var 'services=$(K8S_LIST_SERV)' \
	  -var 'lb_name=$(LB_NAME)'

clean:
	export ACM_ARN=$(ACM_ARN) VPC_CIDR=$(VPC_CIDR) && envsubst < configs/deploy-tls-termination.yaml | kubectl delete -f -
	make destroy
=======
# clean:
# 	kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/aws/patch-configmap-l7.yaml
# 	kubectl delete -f configs/service-l7.yaml 
# 	kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
# 	make destroy
<<<<<<< HEAD
>>>>>>> 3b99211 (multiples correcciones)

destroy:
	cd terraform/ && terraform destroy \
	  -var 'region=$(AWS_REGION)' \
	  -var 'project=$(PROJECT)' \
	  -var 'env=$(ENV)' \
	  -var 'cidr_vpc=$(CIDR_VPC)' \
	  -var 'cidr_pri=$(CIDR_PRI)' \
	  -var 'cidr_pub=$(CIDR_PUB)' \
	  -var 'instance_types=$(K8S_NODE_TYPE)' \
	  -var 'desired_capacity=$(K8S_NODE_SIZE)' \
	  -var 'min_size=$(K8S_NODE_MINI)' \
	  -var 'max_size=$(K8S_NODE_MAXI)' \
	  -var 'eks_version=$(K8S_CLUS_VERS)' \
	  -var 'on_demand_percentage_above_base_capacity=$(K8S_NODE_SPOT)' \
	-auto-approve
>>>>>>> 8f8b6cd (fix travisci)
=======
>>>>>>> e440ee1 (agregando modulo eks y multiples cambios)
=======
>>>>>>> 3f6262e (multiples cambios)
