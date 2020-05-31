PROJECT     = falcon
ENV         = prod
DOMAIN      = punkerside.com
AWS_REGION  = us-east-1
AWS_ID      = $(shell aws sts get-caller-identity --query 'Account' | cut -d'"' -f2)

# variables de red
CIDR_VPC = 172.16.0.0/16
CIDR_PRI = ["172.16.0.0/19","172.16.32.0/19","172.16.64.0/19"]
CIDR_PUB = ["172.16.96.0/19","172.16.128.0/19","172.16.160.0/19"]

K8S_CLUS_VERS = 1.16
K8S_NODE_TYPE = ["r5a.xlarge","m5a.xlarge","r5.xlarge","m5.xlarge"]
K8S_NODE_SIZE = 1
K8S_NODE_MINI = 1
K8S_NODE_MAXI = 4
K8S_NODE_SPOT = 0
K8S_NAMESPACE = monitoring
K8S_LIST_SERV = ["prometheus","grafana","kibana","guestbook"]

quickstart:
	make init
	make apply
	make clean

init:
	cd terraform/ && terraform init

apply:
	cd terraform/ && terraform apply \
	  -var 'region=$(AWS_REGION)' \
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
	  -var 'on_demand_percentage_above_base_capacity=$(K8S_NODE_SPOT)' \
	-auto-approve
	aws eks --region $(AWS_REGION) update-kubeconfig --name $(PROJECT)-$(ENV)
	export ROLE='arn:aws:iam::$(AWS_ID):role/$(PROJECT)-$(ENV)-node' && envsubst < configs/aws-auth-cm.yaml | kubectl apply -f -

metrics:
	$(eval DOWNLOAD_URL = $(shell curl -Ls "https://api.github.com/repos/kubernetes-sigs/metrics-server/releases/latest" | jq -r .tarball_url))
	$(eval DOWNLOAD_VERSION = $(shell grep -o '[^/v]*$$' <<< $(DOWNLOAD_URL)))
	@kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v$(DOWNLOAD_VERSION)/components.yaml

autoscaler:
	@export CLUSTER_NAME=$(PROJECT)-$(ENV) && envsubst < configs/cluster-autoscaler-autodiscover.yaml | kubectl apply -f -
	@kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"
	@kubectl -n kube-system set image deployment.apps/cluster-autoscaler cluster-autoscaler=us.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler:v1.16.5

dashboard:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
	kubectl apply -f configs/eks-admin-service-account.yaml

ingress:
	$(eval ACM_ARN = $(shell cd terraform/ && terraform output aws_acm_certificate))
	$(eval VPC_CIDR = $(shell cd terraform/ && terraform output cidr_block))
	export ACM_ARN=$(ACM_ARN) VPC_CIDR=$(VPC_CIDR) && envsubst < configs/deploy-tls-termination.yaml | kubectl apply -f -

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
	  -f configs/grafana.yml \
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


demo:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-controller.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-service.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-controller.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-service.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-controller.json
	kubectl apply -f guestbook/guestbook-service.json
	export DOMAIN=$(DOMAIN) && envsubst < guestbook/guestbook-ingress.yaml | kubectl apply -f -

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

destroy:
	cd terraform/ && terraform destroy \
	  -var 'region=$(AWS_REGION)' \
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
	  -var 'on_demand_percentage_above_base_capacity=$(K8S_NODE_SPOT)' \
	-auto-approve