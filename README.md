# Elastic Container Service for Kubernetes - Amazon EKS

[![Build Status](https://travis-ci.org/punkerside/kubernetes-demo.svg?branch=master)](https://travis-ci.org/punkerside/kubernetes-demo)
[![GitHub Issues](https://img.shields.io/github/issues/punkerside/kubernetes-demo.svg)](https://github.com/punkerside/kubernetes-demo/issues)
[![GitHub Tag](https://img.shields.io/github/tag-date/punkerside/kubernetes-demo.svg?style=plastic)](https://github.com/punkerside/kubernetes-demo/tags/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Kubernetes es un software de código abierto que le permite implementar y administrar aplicaciones en contenedores a escala.

Amazon EKS administra clústeres de instancias de informática de Amazon EC2 y ejecuta contenedores en ellas con procesos destinados a implementación, mantenimiento y escalado.

<p align="center">
  <img src="docs/img/architecture.png">
</p>

## Prerequisite

* [Instalar eksctl](https://eksctl.io/introduction/installation/)
* [Instalar awscli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

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
* GuestBook

## Despliegue

* ### Cluster y nodos Kubernetes (EKS)

```bash
make create AWS_REGION=us-east-1
```

Para habilitar el acceso por defecto desde el comando **kubectl**:


```bash
ln -s ~/.kube/eksctl/clusters/$CLUSTER_NAME ~/.kube/config
```

* ### Instalando Web UI (Dashboard)

```bash
make addon-dashboard
```

Iniciando **proxy**:

```bash
kubectl proxy
```

Para capturar el **token** de acceso Dashboard:

```bash
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}') | grep "token:"
```

<a href="http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login" target="_blank">http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login</a>

<p align="center">
  <img src="docs/img/dashboard.png">
</p>

* ### Instalando CloudWatch Container Insights

```bash
make addon-cloudwatch AWS_REGION=us-east-1
```

* ### Instalando Metrics Server

```bash
make addon-metrics
```

<p align="center">
  <img src="docs/img/autoscaling-pods.png">
</p>

Para revisar los registros del escalado:

```bash
kubectl get hpa
```

* ### Instalando Cluster Autoscaler

```bash
make addon-autoscaler
```

<p align="center">
  <img src="docs/img/autoscaling-nodos.png">
</p>

Para revisar los registros del escalado:

```bash
kubectl logs -f deployment/cluster-autoscaler -n kube-system
```

* ### Desplegando contenedor de estres

```bash
make container-stress
```

Utilizando un contenedor para enviar consultas **wget** dentro del cluster:

```bash
TIME=$(date "+%H%M%S") && kubectl run -i --tty load-generator-${TIME} --image=busybox /bin/sh
```

Dentro del contenedor iniciamos las consultas de saturacion:

```bash
while true; do wget -q -O- http://stress.default.svc.cluster.local; done
```

* ### Instalando NGINX Ingress Controller

```bash
make ingress-controller
```
<p align="center">
  <img src="docs/img/ingress.png">
</p>

* ### Instalando GuestBook

```bash
make deploy-guestbook
```

Capturar DNS del balanceador asociado al **NGINX Ingress Controller**:

```bash
kubectl get svc --namespace=ingress-nginx ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| OWNER | Nombre del propietario | string | punkerside | no |
| ENV | Nombre del entorno | string | dev | no |
| AWS_REGION | Region de AWS | string | `us-east-1` | no |
| KUBE_VER | Version de Kubernetes | string | `1.14` | no |
| NODE_MIN | Numero minimo de nodos para el escalamiento| string | `1` | no |
| NODE_MAX | Numero minimo de nodos para el escalamiento| string | `10` | no |
| NODE_TYPE | Tipo de instancia de los nodos | list | `["r5a.large", "m5a.large", "t3a.medium"]` | no |

## Eliminar

Para eliminar la infraestructura creada:

```bash
make delete
```

## Authors

[Ivan Echegaray Avendaño](https://github.com/punkerside/)

## License

Apache 2 Licensed. See LICENSE for full details.