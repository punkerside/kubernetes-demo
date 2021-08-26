PROJECT     = falcon
ENV         = k8s
AWS_REGION  = us-east-1
EKS_VERSION = 1.21

cluster:
	@cd terraform/ && terraform init
	@export AWS_DEFAULT_REGION="$(AWS_REGION)" && \
	cd terraform/ && terraform apply \
	  -var 'name=$(PROJECT)-$(ENV)' \
	-auto-approve
	@aws eks update-kubeconfig --name $(PROJECT)-$(ENV) --region $(AWS_REGION)

metrics-server:
	@kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.0/components.yaml

cluster-autoscaler:
	@export EKS_NAME=$(PROJECT)-$(ENV) EKS_VERSION=$(shell curl -s https://api.github.com/repos/kubernetes/autoscaler/releases | grep tag_name | grep cluster-autoscaler | grep $(EKS_VERSION) | cut -d '"' -f4 | cut -d "-" -f3 | head -1) && envsubst < k8s/cluster-autoscaler-autodiscover.yaml | kubectl apply -f -
	@kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false" --overwrite

container-insights:
	@sed 's/{{cluster_name}}/'$(PROJECT)-$(ENV)'/;s/{{region_name}}/'$(AWS_REGION)'/;s/{{http_server_toggle}}/"On"/;s/{{http_server_port}}/"2020"/;s/{{read_from_head}}/"Off"/;s/{{read_from_tail}}/"Off"/' k8s/cwagent.yaml | kubectl apply -f -

xray:
	@eksctl utils associate-iam-oidc-provider --cluster $(PROJECT)-$(ENV) --region $(AWS_REGION) --approve
	@eksctl create iamserviceaccount --name xray-daemon --namespace default --cluster $(PROJECT)-$(ENV) --attach-policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess --override-existing-serviceaccounts --region $(AWS_REGION) --approve
	@kubectl label serviceaccount xray-daemon app=xray-daemon
	@kubectl create -f https://eksworkshop.com/intermediate/245_x-ray/daemonset.files/xray-k8s-daemonset.yaml

xray-sample:
	@kubectl apply -f https://eksworkshop.com/intermediate/245_x-ray/sample-front.files/x-ray-sample-front-k8s.yml
	@kubectl apply -f https://eksworkshop.com/intermediate/245_x-ray/sample-back.files/x-ray-sample-back-k8s.yml

nginx-controller:
	@helm repo add nginx-stable https://helm.nginx.com/stable > /dev/null 2>&1
	@helm repo update > /dev/null 2>&1
	@helm install nginx-ingress nginx-stable/nginx-ingress -f k8s/nginx-controller.yaml

guestbook:
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-controller.json
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-service.json
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-controller.json
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-service.json
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-controller.json
	@kubectl apply -f k8s/guestbook-service.json
	@kubectl apply -f k8s/guestbook-ingress.yaml

destroy:
	@helm uninstall nginx-ingress
	@aws cloudformation delete-stack --stack-name eksctl-$(PROJECT)-$(ENV)-addon-iamserviceaccount-default-xray-daemon --region $(AWS_REGION)
	@cd terraform/ && terraform init
	@export AWS_DEFAULT_REGION="$(AWS_REGION)" && \
	cd terraform/ && terraform destroy \
	  -var 'name=$(PROJECT)-$(ENV)' \
	-auto-approve