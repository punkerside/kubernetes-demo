PROJECT    = eks
ENV        = dev
DOMAIN     = punkerside.com
AWS_REGION = us-east-1
AWS_ZONES  = '$(shell echo '[$(shell aws ec2 describe-availability-zones --region=$(AWS_REGION) --query 'AvailabilityZones[0].ZoneName' --output json),$(shell aws ec2 describe-availability-zones --region=$(AWS_REGION) --query 'AvailabilityZones[1].ZoneName' --output json),$(shell aws ec2 describe-availability-zones --region=$(AWS_REGION) --query 'AvailabilityZones[2].ZoneName' --output json)]')'

K8S_CLUS_VERS = 1.15
K8S_NODE_TYPE = '["r5a.xlarge","m5a.xlarge","r5.xlarge","m5.xlarge"]'
K8S_NODE_SIZE = 1
K8S_NODE_MINI = 1
K8S_NODE_MAXI = 6
K8S_NAMESPACE = monitoring

VPC_ID    = $(shell aws ec2 describe-vpcs --region $(AWS_REGION) --filters Name=tag:Name,Values=eksctl-$(PROJECT)-$(ENV)-cluster/VPC | jq -r '.Vpcs[].VpcId')
ELB_ZONE  = $(shell aws elb describe-load-balancers --region $(AWS_REGION) | jq '.LoadBalancerDescriptions[] | select(.VPCId == "$(VPC_ID)")' | jq -r .CanonicalHostedZoneNameID)
ELB_DNS   = $(shell aws elb describe-load-balancers --region $(AWS_REGION) | jq '.LoadBalancerDescriptions[] | select(.VPCId == "$(VPC_ID)")' | jq -r .CanonicalHostedZoneName)
ELB_IP    = $(shell dig +short $(ELB_DNS) | head -1)
ELB_SSL   = true
DNS_OWNER = true
ACM_ARN   = $(shell aws acm list-certificates --region $(AWS_REGION) | jq '.CertificateSummaryList[] | select(.DomainName == "*.$(DOMAIN)")' | jq -r .CertificateArn)

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

# eliminando cluster kubernetes
delete:
	eksctl delete cluster \
	  --name $(PROJECT)-$(ENV) \
	  --region $(AWS_REGION)
metrics:
	$(eval DOWNLOAD_URL = $(shell curl -Ls "https://api.github.com/repos/kubernetes-sigs/metrics-server/releases/latest" | jq -r .tarball_url))
	$(eval DOWNLOAD_VERSION = $(shell grep -o '[^/v]*$$' <<< $(DOWNLOAD_URL)))
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v$(DOWNLOAD_VERSION)/components.yaml

autoscaler:
	export CLUSTER_NAME=$(PROJECT)-$(ENV) && envsubst < scripts/cluster-autoscaler-autodiscover.yaml | kubectl apply -f -
	@kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"
	@kubectl -n kube-system set image deployment.apps/cluster-autoscaler cluster-autoscaler=us.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler:v1.15.6

ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
ifeq ($(ELB_SSL), true)
	export ACM_ARN=$(ACM_ARN) && envsubst < scripts/service-l7_ssl.yaml | kubectl apply -f -
endif
ifeq ($(ELB_SSL), false)
	kubectl apply -f scripts/service-l7.yaml
endif
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/aws/patch-configmap-l7.yaml

dashboard:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
	kubectl apply -f scripts/eks-admin-service-account.yaml

helm:
	kubectl create namespace $(K8S_NAMESPACE)
	helm repo add stable https://kubernetes-charts.storage.googleapis.com/
	helm repo add elastic https://helm.elastic.co

prometheus:
	helm install prometheus stable/prometheus \
	  --namespace $(K8S_NAMESPACE) \
	  --set alertmanager.enabled=false,pushgateway.enabled=false,server.persistentVolume.storageClass="gp2",server.ingress.enabled="true",server.ingress.hosts[0]="prometheus.$(DOMAIN)"

grafana:
	helm install grafana stable/grafana \
	  -f scripts/grafana.yml \
	  --namespace $(K8S_NAMESPACE) \
	  --set=ingress.enabled=True,ingress.hosts={grafana.$(DOMAIN)}

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

fluent-bit:
	helm install fluent-bit stable/fluent-bit \
	  --namespace $(K8S_NAMESPACE) \
	  --set backend.type=es \
	  --set input.systemd.enabled=true \
	  --set backend.es.host=elasticsearch-master.$(K8S_NAMESPACE).svc.cluster.local

kibana:
	helm install kibana elastic/kibana --namespace $(K8S_NAMESPACE) \
	  --set elasticsearchHosts=http://elasticsearch-master.$(K8S_NAMESPACE).svc.cluster.local:9200,ingress.enabled=true,ingress.hosts[0]="kibana.$(DOMAIN)"

app:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-controller.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-service.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-controller.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-service.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-controller.json
	kubectl apply -f guestbook/guestbook-service.json
	export DOMAIN=$(DOMAIN) && envsubst < guestbook/guestbook-ingress.yaml | kubectl apply -f -

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
