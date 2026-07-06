# ☸️ 30 — Kubernetes Introduction (From Docker to K8s)

> **Session 9 — Bridge to Kubernetes** | Tested on: AlmaLinux 9 with Minikube | Author: Ganesh

You've mastered Docker. Kubernetes (K8s) is the next step — a production-grade container orchestration platform that manages thousands of containers across hundreds of nodes. This note bridges the gap using **Minikube** (a local single-node Kubernetes cluster).

---

## 🔄 Docker vs Kubernetes — Why K8s?

| Feature | Docker Swarm | Kubernetes |
|---|---|---|
| **Ease of setup** | ✅ Very easy | ⚠️ More complex |
| **Production adoption** | Low | Dominant (80%+ of market) |
| **Auto-healing** | Basic | ✅ Advanced |
| **Auto-scaling** | Manual script | ✅ HPA (built-in) |
| **Rolling updates** | ✅ Yes | ✅ Yes + strategies |
| **Service discovery** | DNS | DNS + Ingress |
| **Storage** | Volumes | PV/PVC (dynamic) |
| **Config/Secrets** | Swarm secrets | ConfigMaps + Secrets |
| **Ecosystem** | Limited | ✅ Massive (Helm, Istio, Prometheus…) |
| **Cloud support** | Minimal | ✅ EKS, GKE, AKS native |

> **When to use Swarm:** Small teams, simple stacks, quick setup.  
> **When to use K8s:** Large teams, microservices, cloud-native, production at scale.

---

## 🛠️ Setting Up Minikube (Local K8s)

Minikube runs a single-node Kubernetes cluster inside a Docker container or VM. Perfect for learning.

```bash
# Step 1: Install Minikube binary
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

# Verify
minikube version
# minikube version: v1.33.x

# Step 2: Start Minikube using Docker as the driver
# (Docker must be running)
minikube start --driver=docker

# Step 3: Check status
minikube status
# minikube: Running
# cluster: Running
# kubectl: Correctly Configured

# Step 4: Set up kubectl alias (if not installed separately)
alias kubectl="minikube kubectl --"

# Or install kubectl separately
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# sudo install kubectl /usr/local/bin/kubectl
```

---

## ⚙️ Core Kubernetes Concepts

```
Cluster     = Group of nodes (machines) managed by K8s
Node        = A machine in the cluster (physical/VM/container)
Pod         = Smallest deployable unit — 1 or more containers
Deployment  = Declares desired state (replicas, image, etc.)
Service     = Exposes pods to network (ClusterIP, NodePort, LoadBalancer)
Namespace   = Virtual cluster for isolation (dev/staging/prod)
```

### Kubernetes vs Docker Terminology

| Docker | Kubernetes |
|---|---|
| Container | Pod (wraps containers) |
| `docker run` | Pod manifest / Deployment |
| Compose service | Deployment + Service |
| Swarm stack | Namespace + Deployments |
| Volume | PersistentVolume (PV) |
| Network | Service + Ingress |
| `docker ps` | `kubectl get pods` |

---

## 🚀 First Kubernetes Deployment

```bash
# Get cluster info
kubectl cluster-info
# Kubernetes control plane is running at https://127.0.0.1:32768

# List nodes
kubectl get nodes
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   2m    v1.30.x

# Create a deployment (nginx — 1 replica by default)
kubectl create deployment nginx --image=nginx
# deployment.apps/nginx created

# Check deployment
kubectl get deployments
# NAME    READY   UP-TO-DATE   AVAILABLE   AGE
# nginx   1/1     1            1           30s

# Check pods
kubectl get pods
# NAME                     READY   STATUS    RESTARTS   AGE
# nginx-7854ff8877-abcde   1/1     Running   0          35s

# Expose the deployment as a NodePort service (accessible from host)
kubectl expose deployment nginx --type=NodePort --port=80
# service/nginx exposed

# Check services
kubectl get svc
# NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP        5m
# nginx        NodePort    10.105.123.45   <none>        80:31234/TCP   10s

# Get the URL to access the service
minikube service nginx --url
# http://127.0.0.1:31234

# Access it
curl http://127.0.0.1:31234
```

---

## 📋 Essential kubectl Commands

```bash
# Cluster
kubectl cluster-info          # Cluster endpoints
kubectl get nodes             # List all nodes
kubectl describe node minikube # Detailed node info

# Pods
kubectl get pods              # List pods (default namespace)
kubectl get pods -A           # All namespaces
kubectl describe pod <name>   # Detailed pod info
kubectl logs <pod-name>       # Pod logs
kubectl logs -f <pod-name>    # Follow logs
kubectl exec -it <pod> -- bash  # Shell into pod

# Deployments
kubectl get deployments
kubectl describe deployment nginx
kubectl scale deployment nginx --replicas=3   # Scale up
kubectl rollout status deployment nginx        # Watch rollout

# Services
kubectl get svc
kubectl describe svc nginx

# Delete resources
kubectl delete deployment nginx
kubectl delete svc nginx
```

---

## 🔁 Kubernetes vs Docker Commands Side-by-Side

```bash
# Docker                          # Kubernetes
docker ps -a                      kubectl get pods
docker run -d nginx               kubectl create deployment nginx --image=nginx
docker logs mycontainer           kubectl logs <pod-name>
docker exec -it c bash            kubectl exec -it <pod> -- bash
docker stop mycontainer           kubectl delete pod <pod-name>
docker rm mycontainer             # (pods auto-restart via Deployment)
docker ps --scale                 kubectl scale deployment nginx --replicas=5
```

---

## 🏗️ YAML Manifests — The K8s Way

Instead of `docker run` commands, Kubernetes uses **YAML manifest files**:

```yaml
# deployment.yaml — equivalent to: docker run -d -p 80:80 nginx
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

```bash
# Apply the manifest
kubectl apply -f deployment.yaml

# Get resources
kubectl get all

# Delete resources
kubectl delete -f deployment.yaml
```

---

## 🧹 Minikube Management

```bash
# Stop the cluster (preserves state)
minikube stop

# Delete the cluster completely
minikube delete

# Check minikube status
minikube status

# Open Kubernetes dashboard in browser
minikube dashboard

# SSH into the minikube node
minikube ssh

# Get minikube IP
minikube ip
```

---

## 🗺️ What's Next in Kubernetes

Now that you understand the basics, the K8s learning path continues:

```
Fundamentals  → Pods, Deployments, Services, Namespaces
Storage       → PersistentVolumes, PersistentVolumeClaims, StorageClasses
Config        → ConfigMaps, Secrets, Environment variables
Networking    → Ingress Controllers, NetworkPolicies, DNS
Scaling       → HorizontalPodAutoscaler (HPA), VPA, Cluster Autoscaler
Security      → RBAC, ServiceAccounts, PodSecurityStandards
Packaging     → Helm charts for templating and release management
Observability → Prometheus + Grafana, Loki, Jaeger
CI/CD         → ArgoCD, Flux, GitHub Actions with K8s
Cloud K8s     → EKS (AWS), GKE (Google), AKS (Azure)
```

---

## ⚡ Quick Reference

```bash
# Minikube
minikube start --driver=docker
minikube status
minikube stop
minikube delete
minikube service <svc> --url

# kubectl basics
kubectl get pods / nodes / svc / deployments / all
kubectl create deployment name --image=image
kubectl expose deployment name --type=NodePort --port=80
kubectl scale deployment name --replicas=5
kubectl delete deployment name
kubectl describe pod <name>
kubectl logs <pod> -f
kubectl exec -it <pod> -- bash
kubectl apply -f manifest.yaml
kubectl delete -f manifest.yaml
```

---

> [!TIP]
> Kubernetes is a vast topic. The natural next repo to create: `kubernetes-learning-notes` — following the same structured session-based approach you used here!

---

*← [29 — Docker Secrets](29-docker-secrets.md) | [31 — Conclusion →](31-conclusion.md)*
