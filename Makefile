# variables globales
OWNER = punkerside
ENV   = demo

# variables de proveedor cloud
AWS_REGION = us-east-1
AWS_ZONES  = $(shell aws --region $(AWS_REGION) ec2 describe-availability-zones --filters "Name=state,Values=available" --query 'AvailabilityZones[*].[ZoneName]' --output text | paste -d',' - - | head -n 1)
AWS_GROUP  = $(shell aws --region $(AWS_REGION) autoscaling describe-auto-scaling-groups | grep $(OWNER)-$(ENV) | grep AutoScalingGroupName | cut -d '"' -f 4)

# variables de cluster kubernetes
KUBE_VER   = 1.14
NODE_MIN   = 1
NODE_MAX   = 10
NODE_TYPE  = t3a.medium
KUBECONFIG = $(HOME)/.kube/eksctl/clusters/$(OWNER)-$(ENV)

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
	cat $(HOME)/.kube/config > $(HOME)/.kube/config.save && rm -rf $(HOME)/.kube/config
	ln -s $(HOME)/.kube/eksctl/clusters/$(OWNER)-$(ENV) $(HOME)/.kube/config
>>>>>>> 56d23e3 (fix stress)

# eliminando cluster kubernetes
delete:
	eksctl delete cluster \
	  --name $(OWNER)-$(ENV) \
	  --region=$(AWS_REGION)

# instalando complemento dashboard
addon-dashboard:
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml
	@kubectl apply -f k8s/eks-admin-service-account.yaml

# instalando complemento metrics server
addon-metrics:
	@mkdir -p tmp/ && rm -rf tmp/metrics-server/ && cd tmp/ && git clone https://github.com/kubernetes-incubator/metrics-server.git
	@kubectl apply -f tmp/metrics-server/deploy/1.8+/

# instalando complemento cluster autoscaler
addon-autoscaler:
	@export AWS_GROUP=$(AWS_GROUP) && envsubst < k8s/cluster-autoscaler-autodiscover.yaml | kubectl apply -f -

# desplegando contenedor de estres
container-stress:
	kubectl run container-stress --image=punkerside/container-stress --requests=cpu=200m --limits=cpu=500m --expose --port=80
	kubectl autoscale deployment container-stress --cpu-percent=15 --min=1 --max=180

# instalando nginx ingress controller 
ingress-controller:
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
	@kubectl apply -f k8s/service-l7.yaml
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/aws/patch-configmap-l7.yaml

# desplegando guestbook
deploy-guestbook:
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-controller.json
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-service.json
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-controller.json
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-service.json
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-controller.json
	@kubectl apply -f guestbook/service.json
	@kubectl apply -f guestbook/ingress.yaml