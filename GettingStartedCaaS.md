
# Getting Started with Podman & Intel CaaS
[Main](README.md)

## Prerequisites
- Podman installed (with WSL backend on Windows)
- Access to Intel CaaS registry (`amr-registry-pre.caas.intel.com`)
- `kubectl` configured for your CaaS cluster

## Build & Run Locally with Podman
```shell
podman build -t colorbox:0.2 .
podman run -d --name colorbox -p 5011:5011 colorbox:0.2
```

### Verify locally
```shell
curl http://localhost:5011/
curl -X POST http://localhost:5011/box/red
curl http://localhost:5011/box
```

### Stop & remove
```shell
podman stop colorbox
podman rm colorbox
```

## Push to Intel CaaS Registry
Registry: https://amr-registry-pre.caas.intel.com/
Project: ditwebapp

```shell
podman login amr-registry-pre.caas.intel.com
podman tag colorbox:0.2 amr-registry-pre.caas.intel.com/ditwebapp/colorbox:0.2
podman push amr-registry-pre.caas.intel.com/ditwebapp/colorbox:0.2
```

## Deploy to Intel CaaS (Kubernetes)
```shell
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### Verify deployment
```shell
kubectl get pods -l app=colorbox
kubectl get svc colorbox
```

### View logs
```shell
kubectl logs -l app=colorbox
```

### Remove deployment
```shell
kubectl delete -f k8s/service.yaml
kubectl delete -f k8s/deployment.yaml
```
