PROJECT    = eks
ENV        = staging
DOMAIN     = punkerside.com
AWS_REGION = us-east-1
AWS_ZONES  = '$(shell echo '[$(shell aws ec2 describe-availability-zones --region=$(AWS_REGION) --query 'AvailabilityZones[0].ZoneName' --output json),$(shell aws ec2 describe-availability-zones --region=$(AWS_REGION) --query 'AvailabilityZones[1].ZoneName' --output json),$(shell aws ec2 describe-availability-zones --region=$(AWS_REGION) --query 'AvailabilityZones[2].ZoneName' --output json)]')'

K8S_CLUS_VERS = 1.15
K8S_NODE_TYPE = '["r5a.xlarge","m5a.xlarge","r5.xlarge","m5.xlarge"]'
K8S_NODE_SIZE = 2
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

create:
	export \
	  NAME=$(PROJECT)-$(ENV) \
	  AWS_REGION=$(AWS_REGION) \
	  AWS_ZONES=$(AWS_ZONES) \
	  K8S_CLUS_VERS=$(K8S_CLUS_VERS) \
	  K8S_NODE_TYPE=$(K8S_NODE_TYPE) \
	  K8S_NODE_SIZE=$(K8S_NODE_SIZE) \
	  K8S_NODE_MINI=$(K8S_NODE_MINI) \
	  K8S_NODE_MAXI=$(K8S_NODE_MAXI) \
	&& envsubst < scripts/cluster.yaml | eksctl create cluster --auto-kubeconfig -f -
	aws eks --region $(AWS_REGION) update-kubeconfig --name $(PROJECT)-$(ENV)

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
