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

## Recursos desplegados

### Amazon AWS

* Virtual Private Cloud (VPC)
* Identity and Access Management (IAM)
* Elastic Container Service for Kubernetes (EKS)
* EC2 Auto Scaling
* Elastic Load Balancing (ELB)

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

## Despliegue

1\. Crear cluster y nodos

```bash
make create AWS_REGION=us-east-1
```

2\. Instalar Metrics Server

```bash
make metrics
```

Para revisar los registros del escalado de pods: ``kubectl get hpa``

3\. Instalando Web UI (Dashboard)

```bash
make dashboard
```

Para capturar el token: ``kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}') | grep "token:" | awk '{print $2}'``

<a href="http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login" target="_blank">http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login</a>

<p align="center">
  <img src="docs/img/dashboard.png">
</p>

4\. Instalando Cluster Autoscaler

```bash
make autoscaler
```

Para revisar los registros del escalado: ``kubectl logs -f deployment/cluster-autoscaler -n kube-system``



5\. Iniciando NGINX Ingress Controller:

```bash
kubectl ingress
```

<p align="center">
  <img src="docs/img/ingress.png">
</p>

6\. Instalando Helm

```bash
kubectl helm
```

7\. Instalando Prometheus

```bash
kubectl prometheus
```

8\. Instalando Grafana

```bash
kubectl grafana
```

9\. Instalando Elasticsearch

```bash
kubectl elasticsearch
```

10\. Instalando Fluent-Bit

```bash
kubectl fluent-bit
```

11\. Instalando Kibana

```bash
kubectl kibana
```

12\. Desplegando GuestBook

```bash
kubectl guestbook-go
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| PROJECT | Nombre del proyecto | string | kubernetes | no |
| ENV | Nombre del entorno | string | demo | no |
| DOMAIN | Nombre del dominio | string | `punkerside.com` | no |
| AWS_REGION | Region de AWS | string | `us-east-1` | no |
| K8S_CLUS_VERS | Version de Kubernetes | string | `1.15` | no |
| K8S_NODE_TYPE | Tipo de instancia de los nodos | list | `["r5a.xlarge", "m5a.xlarge", "t3a.medium"]` | no |
| K8S_NODE_SIZE | Numero de nodos | string | `3` | no |
| K8S_NODE_MINI | Numero minimo de nodos | string | `1` | no |
| K8S_NODE_MAXI | Numero maximo de nodos | string | `6` | no |

## Eliminar

```bash
make delete
```

## Autor

[Ivan Echegaray Avendaño](https://github.com/punkerside/)