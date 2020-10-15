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

## **Recursos desplegados**

### **1. Amazon AWS**

* Virtual Private Cloud (VPC)
* Elastic Container Service for Kubernetes (EKS)
* Auto Scaling Groups (EC2)

### **2. Kubernetes**

* Metrics Server
* Cluster Autoscaler (CA)
* Traefik
* Grafana
* Prometheus
* Loki
* Fluent Bit
* Jaeger

## **Variables**

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `PROJECT` | Nombre del proyecto | string | `falcon` | no |
| `ENV` | Nombre del entorno | string | `k8s` | no |

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

<<<<<<< HEAD
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

=======
>>>>>>> 3f6262e (multiples cambios)
<p align="center">
  <img src="docs/img/02.png">
</p>

4. Instalando **Charts**

```bash
make charts
```

5. Instalar **Jaeger**:

```bash
make jaeger
```

* Desplegar aplicacion **HotROD**

```bash
make hotrod
```

* Acceder al servicio HotROD mediante localhost

```bash
kubectl port-forward service/hotrod 8080:8080
```

<a href="http://localhost:8080/" target="_blank">http://localhost:8080/</a>

<p align="center">
  <img src="docs/img/06.png">
</p>

* Acceder al servicio Jaeger mediante localhost

```bash
kubectl -n monitoring port-forward service/jaeger-query 16686:80
```

<a href="http://localhost:16686/" target="_blank">http://localhost:16686/</a>

<p align="center">
  <img src="docs/img/07.png">
</p>

6. Instalando **Prometheus**

```bash
make prometheus
```

* Acceder al servicio mediante localhost

```bash
kubectl -n monitoring port-forward service/prometheus-server 9090:80
```

<a href="http://localhost:9090/" target="_blank">http://localhost:9090/</a>

<p align="center">
  <img src="docs/img/03.png">
</p>

7. Instalar **Loki**:

```bash
make loki
```

* Acceder al servicio mediante localhost

```bash
kubectl -n monitoring port-forward service/loki 3100
```

<a href="http://localhost:3100/api/prom/label" target="_blank">http://localhost:3100/api/prom/label</a>

<p align="center">
  <img src="docs/img/04.png">
</p>

8. Instalar **Fluent Bit**:

```bash
make fluent-bit
```

<<<<<<< HEAD
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
=======
* Acceder al servicio mediante localhost

```bash
kubectl -n monitoring port-forward daemonset/fluent-bit-fluent-bit-loki 2020
```
>>>>>>> 3f6262e (multiples cambios)

<a href="http://localhost:2020/api/v1/metrics/prometheus" target="_blank">http://localhost:2020/api/v1/metrics/prometheus</a>

<p align="center">
  <img src="docs/img/05.png">
</p>

<<<<<<< HEAD
<<<<<<< HEAD
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
=======
10. Instalar **Grafana**
=======
9. Instalar **Grafana**
>>>>>>> 89caafc (corrigiendo documentacion)

```bash
make grafana
```

* Acceder al servicio mediante localhost

```bash
kubectl -n monitoring port-forward service/grafana 8300:80
```

<a href="http://localhost:8300/" target="_blank">http://localhost:8300/</a>

<p align="center">
  <img src="docs/img/08.png">
</p>

Plantilla JSON para la creacion del [Dashboard](https://github.com/punkerside/terraform-aws-eks/blob/master/k8s/grafana.json).

10. Instalando **Traefik**

```bash
make traefik
```

* Acceder al dashboard del servicio mediante localhost

<a href="http://localhost:9000/dashboard/#/" target="_blank">http://localhost:9000/dashboard/#/</a>

```bash
kubectl port-forward $(kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000
```

<p align="center">
  <img src="docs/img/09.png">
</p>


>>>>>>> 3f6262e (multiples cambios)
## Eliminar

Para eliminar la infraestructura creada:

```bash
make destroy
```

## Authors

<<<<<<< HEAD
<<<<<<< HEAD
[Ivan Echegaray Avendaño](https://github.com/punkerside/)

## License

Apache 2 Licensed. See LICENSE for full details.
=======
[Ivan Echegaray Avendaño](https://www.youracclaim.com/users/punkerside/badges)
>>>>>>> 8f8b6cd (fix travisci)
=======
[Ivan Echegaray Avendaño](https://github.com/punkerside/)
>>>>>>> 3f6262e (multiples cambios)
