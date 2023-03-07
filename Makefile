<<<<<<< HEAD
# variables globales
OWNER = punkerside
ENV   = dev

# variables de proveedor cloud
=======
PROJECT    = kubernetes
ENV        = dev
DOMAIN     = punkerside.com
>>>>>>> 8ababbf (corrigiendo errores)
AWS_REGION = us-east-1
AWS_ZONES  = '$(shell echo '[$(shell aws ec2 describe-availability-zones --region=$(AWS_REGION) --query 'AvailabilityZones[0].ZoneName' --output json),$(shell aws ec2 describe-availability-zones --region=$(AWS_REGION) --query 'AvailabilityZones[1].ZoneName' --output json)]')'
AWS_GROUP  = $(shell aws --region $(AWS_REGION) autoscaling describe-auto-scaling-groups | grep $(OWNER)-$(ENV) | grep AutoScalingGroupName | cut -d '"' -f 4)

# variables de cluster kubernetes
KUBE_VER   = 1.14
NODE_MIN   = 1
NODE_MAX   = 10
NODE_TYPE  = '["r5a.large", "m5a.large", "t3a.medium"]'
KUBECONFIG = "$(HOME)/.kube/eksctl/clusters/$(OWNER)-$(ENV)"

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
	  --name $(OWNER)-$(ENV) \
	  --region=$(AWS_REGION)

# instalando complemento dashboard
addon-dashboard:
	@kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml
	@kubectl --kubeconfig $(KUBECONFIG) apply -f k8s/eks-admin-service-account.yaml

# instalando complemento cloudwatch
addon-cloudwatch:
	curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/$(OWNER)-$(ENV)/;s/{{region_name}}/$(AWS_REGION)/" | kubectl --kubeconfig $(KUBECONFIG) apply -f -

# instalando complemento metrics server
addon-metrics:
	@mkdir -p tmp/ && rm -rf tmp/metrics-server/ && cd tmp/ && git clone https://github.com/kubernetes-incubator/metrics-server.git > /dev/null 2>&1
	@kubectl --kubeconfig $(KUBECONFIG) apply -f tmp/metrics-server/deploy/1.8+/

# instalando complemento cluster autoscaler
addon-autoscaler:
	@export AWS_GROUP=$(AWS_GROUP) && envsubst < k8s/cluster-autoscaler-autodiscover.yaml | kubectl --kubeconfig $(KUBECONFIG) apply -f -

# desplegando contenedor de estres
container-stress:
	@kubectl --kubeconfig $(KUBECONFIG) apply -f stress/service.yaml
	@kubectl --kubeconfig $(KUBECONFIG) apply -f stress/hpa.yaml

# instalando nginx ingress controller 
ingress-controller:
	@kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
	@kubectl --kubeconfig $(KUBECONFIG) apply -f k8s/service-l7.yaml
	@kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/aws/patch-configmap-l7.yaml

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

guestbook-go:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-controller.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-service.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-controller.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-service.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-controller.json
	kubectl apply -f guestbook/guestbook-service.json
	export DOMAIN=$(DOMAIN) && envsubst < guestbook/guestbook-ingress.yaml | kubectl apply -f -

dns:
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
