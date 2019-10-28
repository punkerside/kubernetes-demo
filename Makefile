# variables globales
OWNER = punkerside
ENV   = dev

# variables de proveedor cloud
AWS_REGION = us-east-1
AWS_ZONES  = '$(shell echo '[$(shell aws ec2 describe-availability-zones --region=$(AWS_REGION) --query 'AvailabilityZones[0].ZoneName' --output json),$(shell aws ec2 describe-availability-zones --region=$(AWS_REGION) --query 'AvailabilityZones[1].ZoneName' --output json)]')'
AWS_GROUP  = $(shell aws --region $(AWS_REGION) autoscaling describe-auto-scaling-groups | grep $(OWNER)-$(ENV) | grep AutoScalingGroupName | cut -d '"' -f 4)

# variables de cluster kubernetes
KUBE_VER   = 1.14
NODE_MIN   = 1
NODE_MAX   = 10
NODE_TYPE  = '["r5a.large", "m5a.large", "t3a.medium"]'
KUBECONFIG = "$(HOME)/.kube/eksctl/clusters/$(OWNER)-$(ENV)"

# creando cluster kubernetes
create:
	export \
	  NAME=$(OWNER)-$(ENV) \
	  AWS_REGION=$(AWS_REGION) \
	  AWS_ZONES=$(AWS_ZONES) \
	  KUBE_VER=$(KUBE_VER) \
	  NODE_TYPE=$(NODE_TYPE) \
	  NODE_MIN=$(NODE_MIN) \
	  NODE_MAX=$(NODE_MAX) \
	&& envsubst < k8s/cluster.yaml | eksctl create cluster --auto-kubeconfig -f -

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

# desplegando guestbook
deploy-guestbook:
	@kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-controller.json
	@kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-service.json
	@kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-controller.json
	@kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-service.json
	@kubectl --kubeconfig $(KUBECONFIG) apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-controller.json
	@kubectl --kubeconfig $(KUBECONFIG) apply -f guestbook/service.json
	@kubectl --kubeconfig $(KUBECONFIG) apply -f guestbook/ingress.yaml