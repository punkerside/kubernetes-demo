PROJECT    = kubernetes
ENV        = dev
DOMAIN     = punkerside.com
AWS_REGION = us-east-1
AWS_ZONES  = '$(shell echo '[$(shell aws ec2 describe-availability-zones --region=$(AWS_REGION) --query 'AvailabilityZones[0].ZoneName' --output json),$(shell aws ec2 describe-availability-zones --region=$(AWS_REGION) --query 'AvailabilityZones[1].ZoneName' --output json)]')'

K8S_CLUS_VERS = 1.15
K8S_NODE_TYPE = '["r5a.xlarge", "m5a.xlarge", "t3a.medium"]'
K8S_NODE_SIZE = 3
K8S_NODE_MINI = 1
K8S_NODE_MAXI = 6
K8S_NAMESPACE = monitoring

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
	@rm -rf metrics-server-$(DOWNLOAD_VERSION) metrics-server-$(DOWNLOAD_VERSION).tar.gz
	curl -Ls $(DOWNLOAD_URL) -o metrics-server-$(DOWNLOAD_VERSION).tar.gz
	@mkdir metrics-server-$(DOWNLOAD_VERSION)
	tar -xzf metrics-server-$(DOWNLOAD_VERSION).tar.gz --directory metrics-server-$(DOWNLOAD_VERSION) --strip-components 1
	kubectl apply -f metrics-server-$(DOWNLOAD_VERSION)/deploy/1.8+/

dashboard:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
	kubectl apply -f scripts/eks-admin-service-account.yaml

autoscaler:
	export CLUSTER_NAME=$(PROJECT)-$(ENV) && envsubst < scripts/cluster-autoscaler-autodiscover.yaml | kubectl apply -f -

ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
	kubectl apply -f scripts/service-l7.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/aws/patch-configmap-l7.yaml

helm:
	kubectl create namespace $(K8S_NAMESPACE)
	helm repo add stable https://kubernetes-charts.storage.googleapis.com/
	helm repo add elastic https://helm.elastic.co

prometheus:
	helm install prometheus stable/prometheus \
	  --namespace $(K8S_NAMESPACE) \
	  --set alertmanager.persistentVolume.storageClass="gp2",server.persistentVolume.storageClass="gp2",server.ingress.enabled="true",server.ingress.hosts[0]="prometheus.$(DOMAIN)"

grafana:
	helm install grafana stable/grafana \
	  -f scripts/grafana.yml \
	  --namespace $(K8S_NAMESPACE) \
	  --set=ingress.enabled=True,ingress.hosts={grafana.$(DOMAIN)} \
	  --set rbac.create=true
	kubectl get secret -n $(K8S_NAMESPACE) grafana -o jsonpath="{.data.admin-password}" | base64 --decode

elasticsearch:
	helm install elasticsearch elastic/elasticsearch --namespace $(K8S_NAMESPACE) \
	  --set persistence.enabled="false"

fluent-bit:
	helm install fluent-bit stable/fluent-bit \
	  --namespace $(K8S_NAMESPACE) \
	  --set backend.type=es \
	  --set input.systemd.enabled=true \
	  --set backend.es.host=elasticsearch-master.$(K8S_NAMESPACE).svc.cluster.local

kibana:
	helm install kibana elastic/kibana --namespace $(K8S_NAMESPACE) \
	  --set elasticsearchHosts=http://elasticsearch-master.$(K8S_NAMESPACE).svc.cluster.local:9200,ingress.enabled=true,ingress.hosts[0]="kibana.$(DOMAIN)"

guestbook-demo:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-controller.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-service.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-controller.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-service.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-controller.json
	kubectl apply -f guestbook/guestbook-service.json
	export DOMAIN=$(DOMAIN) && envsubst < guestbook/guestbook-ingress.yaml | kubectl apply -f -

dns:
	$(eval LB_DNS = $(shell kubectl get services -o wide --all-namespaces | grep ingress-nginx | awk '{print $$5}'))
	$(eval LB_IP = $(shell dig +short $(LB_DNS) | head -1))
	@echo "$(LB_IP)	prometheus.$(DOMAIN) grafana.$(DOMAIN) kibana.$(DOMAIN) guestbook.$(DOMAIN)"
