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

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| PROJECT | Nombre del proyecto | string | `kubernetes` | no |
| ENV | Nombre del entorno | string | `demo` | no |
| DOMAIN | Nombre del dominio | string | `punkerside.com` | no |
| AWS_REGION | Region de AWS | string | `us-east-1` | no |
| K8S_CLUS_VERS | Version de Kubernetes | string | `1.15` | no |
| K8S_NODE_TYPE | Tipo de instancia de los nodos | list | `["r5a.xlarge", "m5a.xlarge", "t3a.medium"]` | no |
| K8S_NODE_SIZE | Numero de nodos | string | `3` | no |
| K8S_NODE_MINI | Numero minimo de nodos | string | `1` | no |
| K8S_NODE_MAXI | Numero maximo de nodos | string | `6` | no |

## Despliegue

1. Crear cluster y nodos

```bash
make create AWS_REGION=us-east-1
```

2. Instalando Cluster Autoscaler

```bash
make autoscaler
```

Para revisar los registros del escalado: ``kubectl logs -f deployment/cluster-autoscaler -n kube-system``

3. Instalar Metrics Server

```bash
ln -s ~/.kube/eksctl/clusters/$CLUSTER_NAME ~/.kube/config
```

Para iniciar el escalado de pods:

```bash
kubectl run httpd --image=httpd --requests=cpu=100m --limits=cpu=200m --expose --port=80
kubectl autoscale deployment httpd --cpu-percent=20 --min=1 --max=20
kubectl run apache-bench -i --tty --rm --image=httpd -- ab -n 500000 -c 1000 http://httpd.default.svc.cluster.local/
```

Para revisar los registros del escalado: ``kubectl get hpa``

<p align="center">
  <img src="docs/img/01.png">
</p>

4. Instalando Web UI (Dashboard)

```bash
make addon-dashboard
```

Iniciar dashboard: ``kubectl proxy``

Capturar token: ``kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}') | grep "token:" | awk '{print $2}'``

Acceso al dashboard: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login

<p align="center">
  <img src="docs/img/dashboard.png">
</p>

<<<<<<< HEAD
4. Instalando Cluster Autoscaler

```bash
make addon-cloudwatch AWS_REGION=us-east-1
```

Para iniciar el escalado de nodos:

```bash
kubectl create deployment autoscaler-demo --image=nginx
kubectl scale deployment autoscaler-demo --replicas=100
```

Para revisar los registros del escalado: ``kubectl logs -f deployment/cluster-autoscaler -n kube-system``

=======
>>>>>>> 31e81a3 (agregando terraform para la creacion de dns)
5. Iniciando NGINX Ingress Controller:

```bash
make ingress
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

6. Instalando Helm

```bash
make helm
```

7. Instalando Prometheus

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

<p align="center">
  <img src="docs/img/02.png">
</p>

Para validar el servicio: http://prometheus.punkerside.com

8. Instalando Grafana

```bash
make grafana DOMAIN=punkerside.com
```

Contraseña admin: ``kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode``

Para validar el servicio: http://grafana.punkerside.com

<p align="center">
  <img src="docs/img/03.png">
</p>

9. Instalando Elasticsearch

```bash
make elasticsearch
```

10. Instalando Fluent-Bit

```bash
make fluent-bit
```

11. Instalando Kibana

```bash
make kibana DOMAIN=punkerside.com
```

Para validar el servicio: http://kibana.punkerside.com

<p align="center">
  <img src="docs/img/04.png">
</p>

12. Desplegando GuestBook (aplicación demo)

```bash
make guestbook-demo DOMAIN=punkerside.com
```

<<<<<<< HEAD
Para visitar el GuestBook: ``http://guestbook.punkerside.com``
>>>>>>> 8ababbf (corrigiendo errores)
=======
Para validar el servicio: http://guestbook.punkerside.com

<p align="center">
  <img src="docs/img/05.png">
</p>
>>>>>>> 067f3c0 (modificando documentacion y corrigiendo procesos automatizados)

## Eliminar

Para eliminar la infraestructura creada:

```bash
make delete
```

## Authors

[Ivan Echegaray Avendaño](https://github.com/punkerside/)

## License

Apache 2 Licensed. See LICENSE for full details.