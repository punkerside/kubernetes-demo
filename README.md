# Elastic Container Service for Kubernetes - Amazon EKS

[![Build Status](https://travis-ci.org/punkerside/kubernetes-demo.svg?branch=master)](https://travis-ci.org/punkerside/kubernetes-demo)
[![GitHub Issues](https://img.shields.io/github/issues/punkerside/kubernetes-demo.svg)](https://github.com/punkerside/kubernetes-demo/issues)
[![GitHub Tag](https://img.shields.io/github/tag-date/punkerside/kubernetes-demo.svg?style=plastic)](https://github.com/punkerside/kubernetes-demo/tags/)

<p align="center">
  <img src="docs/img/architecture.png">
</p>

## **Prerrequisitos**

* [Instalar Terraform](https://www.terraform.io/downloads.html)
* [Instalar AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
* [Instalar Helm](https://helm.sh/docs/intro/install/)
* [Instalar Kubectl](https://kubernetes.io/es/docs/tasks/tools/install-kubectl/#instalar-kubectl)
* [Instalar eksctl](https://github.com/weaveworks/eksctl)

## **Recursos desplegados**

### **1. Amazon AWS**

* Virtual Private Cloud (VPC)
* Identity and Access Management (IAM)
* Elastic Container Service for Kubernetes (EKS)
* Amazon EKS managed node (EKS)

### **2. Kubernetes**

* Metrics Server
* Cluster Autoscaler (CA)
* AWS Container Insights
* AWS XRay
* Nginx Controller
* Guestbook

## **Variables**

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `PROJECT` | Nombre del proyecto | string | `falcon` | no |
| `ENV` | Nombre del entorno | string | `k8s` | no |
| `AWS_REGION` | Region de Amazon AWS | string | `us-east-1` | no |
| `EKS_VERSION` | Version de Kubernetes | string | `1.21` | no |

## **Uso**

1. Crear cluster y nodes

```bash
make cluster
```

2. Instalar **Metrics Server**

```bash
make metrics-server
```

3. Instalar **Cluster Autoscaler**

```bash
make cluster-autoscaler
```

* Iniciar el escalado de pods y nodos:

```bash
kubectl apply -f https://k8s.io/examples/application/php-apache.yaml
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=100
kubectl run apache-bench -i --tty --rm --image=httpd -- ab -n 5000000 -c 1000 http://php-apache.default.svc.cluster.local/
```

* Revisar el escalado de pods:

```bash
kubectl get hpa --watch
```

<p align="center">
  <img src="docs/img/01.png">
</p>

* Revisar el escalado de nodos:

```bash
kubectl get nodes --watch
```

<p align="center">
  <img src="docs/img/00.png">
</p>

* Revisar logs de cluster-autoscaler:

```bash
kubectl logs -f deployment/cluster-autoscaler -n kube-system
```

<p align="center">
  <img src="docs/img/02.png">
</p>

4. Instalar **AWS Container Insights**

```bash
make container-insights
```

<p align="center">
  <img src="docs/img/03.png">
</p>

5. Instalar **AWS X-Ray**

```bash
make xray
```

<p align="center">
  <img src="docs/img/04.png">
</p>

6. Desplegar **AWS X-Ray Sample**

```bash
make xray-sample
```

* Capturar DNS del balanceador asociado al servicio:

```bash
kubectl get service x-ray-sample-front-k8s -o wide
```

<p align="center">
  <img src="docs/img/05.png">
</p>

7. Desplegar **Nginx Ingress Controller**

```bash
make nginx-controller
```

8. Desplegar **guestbook**

```bash
make guestbook
```

* Capturar DNS del balanceador asociado al Nginx Ingress Controller:

```bash
kubectl get service nginx-ingress-nginx-ingress -o wide
```

## Eliminar

```bash
make destroy
```

## Autor

[Ivan Echegaray Avendaño](https://github.com/punkerside/)