# Elastic Container Service for Kubernetes - Amazon EKS

[![Build Status](https://travis-ci.org/punkerside/kubernetes-demo.svg?branch=master)](https://travis-ci.org/punkerside/kubernetes-demo)
[![GitHub Issues](https://img.shields.io/github/issues/punkerside/kubernetes-demo.svg)](https://github.com/punkerside/kubernetes-demo/issues)
[![GitHub Tag](https://img.shields.io/github/tag-date/punkerside/kubernetes-demo.svg?style=plastic)](https://github.com/punkerside/kubernetes-demo/tags/)

Kubernetes es un software de código abierto que le permite implementar y administrar aplicaciones en contenedores a escala.

Amazon EKS administra clústeres de instancias de informática de Amazon EC2 y ejecuta contenedores en ellas con procesos destinados a implementación, mantenimiento y escalado.

<p align="center">
  <img src="docs/img/architecture.png">
</p>

## Prerequisite

* [Instalar Terraform](https://www.terraform.io/downloads.html)
* [Instalar AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
* [Instalar Helm](https://helm.sh/docs/intro/install/)
* [Instalar Kubectl](https://kubernetes.io/es/docs/tasks/tools/install-kubectl/#instalar-kubectl)

**NOTA:** Configurar las credenciales en el servicio [AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/configure/).

## Recursos desplegados

### Amazon AWS

* Virtual Private Cloud (VPC)
* Elastic Container Service for Kubernetes (EKS)
* EC2 Auto Scaling
* Elastic Load Balancing (ELB)
* Identity and Access Management (IAM)
* CloudWatch Container Insights

### Kubernetes

* Web UI (Dashboard)
* Metrics Server
* Cluster Autoscaler (CA)
* NGINX Ingress Controller
* Prometheus
* Grafana
* Fluent-bit
* ElasticSearch
* Kibana
* GuestBook

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| PROJECT | Nombre del proyecto | string | `falcon` | no |
| ENV | Nombre del entorno | string | `staging` | no |
| AWS_REGION | Region de AWS | string | `us-east-1` | no |
| CIDR_VPC | CIDR de la VPC | string | `172.16.0.0/16` | no |
| CIDR_PRI | CIDR de las subnets privadas | list | `["172.16.0.0/19","172.16.32.0/19","172.16.64.0/19"]` | no |
| CIDR_PUB | CIDR de las subnets publicas | list | `["172.16.96.0/19","172.16.128.0/19","172.16.160.0/19"]` | no |
| K8S_CLUS_VERS | Version de Kubernetes | string | `1.16` | no |
| K8S_NODE_TYPE | Tipo de instancia de los nodos | list | `["r5a.xlarge","m5a.xlarge","r5.xlarge","m5.xlarge"]` | no |
| K8S_NODE_SIZE | Numero de nodos | string | `1` | no |
| K8S_NODE_MINI | Numero minimo de nodos | string | `1` | no |
| K8S_NODE_MAXI | Numero maximo de nodos | string | `4` | no |
| K8S_NODE_SPOT | % de instancias "on-demand" | string | `0` | no |

## Uso

**1. Crear cluster y nodes**

```bash
make cluster
make nodes
```

**2. Instalar Metrics Server**

```bash
ln -s ~/.kube/eksctl/clusters/$CLUSTER_NAME ~/.kube/config
```

**3. Instalando Cluster Autoscaler**

```bash
make autoscaler
```

Iniciar el escalado de nodos y pods:

```bash
kubectl apply -f https://k8s.io/examples/application/php-apache.yaml
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=20
kubectl run apache-bench -i --tty --rm --image=httpd -- ab -n 5000000 -c 1000 http://php-apache.default.svc.cluster.local/
```

Revisar el escalado de nodos:

```bash
kubectl get nodes --watch
```

<p align="center">
  <img src="docs/img/00.png">
</p>

Revisar el escalado de pods:

```bash
kubectl get hpa --watch
```

<p align="center">
  <img src="docs/img/01.png">
</p>

**4. Instalando Web UI (Dashboard)**

```bash
make addon-dashboard
```

Capturar token:

```bash
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}') | grep "token:" | awk '{print $2}'
```

Acceder al dashboard mediante localhost:

```bash
kubectl proxy
```

Acceso al Dashboard:

 http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login

<p align="center">
  <img src="docs/img/dashboard.png">
</p>

**5. Instalando NGINX Ingress Controller**

```bash
make ingress
```

<p align="center">
  <img src="docs/img/ingress.png">
</p>

**6. Instalando Helm**

```bash
make helm
```

**7. Instalando Prometheus**

```bash
<<<<<<< HEAD
<<<<<<< HEAD
kubectl get svc --namespace=ingress-nginx ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| OWNER | Nombre del propietario | string | punkerside | no |
| ENV | Nombre del entorno | string | dev | no |
| AWS_REGION | Region de AWS | string | `us-east-1` | no |
| KUBE_VER | Version de Kubernetes | string | `1.14` | no |
| NODE_MIN | Numero minimo de nodos | string | `1` | no |
| NODE_MAX | Numero maximo de nodos | string | `10` | no |
| NODE_TYPE | Tipo de instancia de los nodos | list | `["r5a.large", "m5a.large"]` | no |
=======
kubectl prometheus
=======
make prometheus
>>>>>>> 4ee1782 (corregir readme)
```

Acceder al servicio mediante localhost: ```kubectl port-forward -n monitoring service/prometheus-server 8002:80```

<p align="center">
  <img src="docs/img/02.png">
</p>

**8. Instalando Grafana**

```bash
make grafana
```

Contraseña admin:

```bash
kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

Acceder al servicio mediante localhost: ```kubectl port-forward -n monitoring service/grafana 8003:80```

<p align="center">
  <img src="docs/img/03.png">
</p>

**9. Instalando Elasticsearch**

```bash
make elasticsearch
```

**10. Instalando Fluent-Bit**

```bash
make fluent-bit
```

**11. Instalando Kibana**

```bash
make kibana
```

Acceder al servicio mediante localhost: ```kubectl port-forward -n monitoring service/kibana-kibana 8004:80```

<p align="center">
  <img src="docs/img/04.png">
</p>

**12. Desplegando GuestBook (aplicación demo)**

```bash
make demo
```

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
Para validar el servicio: http://guestbook.punkerside.com
=======
Para validar el servicio https://guestbook.punkerside.com
>>>>>>> a905dec (fix readme)
=======
Para validar el servicio: https://guestbook.punkerside.com
>>>>>>> 6dc8381 (fix readme)
=======
Acceder al servicio mediante Ingress Controller: ```kubectl get ingress```
>>>>>>> 3b99211 (multiples correcciones)

<p align="center">
  <img src="docs/img/05.png">
</p>

<<<<<<< HEAD
<<<<<<< HEAD
=======
**13. Configurar registros DNS publicos sobre AWS Route53**

```bash
make dns
```

>>>>>>> 6dc8381 (fix readme)
=======
>>>>>>> 3b99211 (multiples correcciones)
## Eliminar

Para eliminar la infraestructura creada:

```bash
make destroy
```

## Authors

<<<<<<< HEAD
[Ivan Echegaray Avendaño](https://github.com/punkerside/)

## License

Apache 2 Licensed. See LICENSE for full details.
=======
[Ivan Echegaray Avendaño](https://www.youracclaim.com/users/punkerside/badges)
>>>>>>> 8f8b6cd (fix travisci)
