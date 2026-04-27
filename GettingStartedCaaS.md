
# Getting Started with Podman & Intel CaaS
[Main](README.md)

## Prerequisites
- Podman installed (with WSL backend on Windows)
- Valid IAPM ID and AGS entitlement: `CaaS Users` (and `CaaS AD Users` if ITS)
- Access to Harbor project `mdata-toolkit` on `amr-registry.caas.intel.com` (request via https://goto.intel.com/caasrequest)
- Access to Rancher project / namespace `mdata-toolkit` on cluster `amr-fm-compute-cluster`
- Kubeconfig downloaded from https://amr.caas.intel.com/ → cluster `amr-fm-compute-cluster` → "Download Kubeconfig"
- Intel proxies configured (Windows cmd):
  ```
  setx HTTP_PROXY "http://proxy-dmz.intel.com:912" && setx HTTPS_PROXY "http://proxy-dmz.intel.com:912" && setx NO_PROXY "localhost,127.0.0.0/8,10.0.0.0/8,.intel.com,127.0.0.1"
  ```

### Configure kubectl
Place kubeconfig at `%USERPROFILE%\.kube\config`, or point `KUBECONFIG` at the file in this repo:
```powershell
$env:KUBECONFIG = "$PWD\amr-fm-compute-cluster.yaml"
kubectl -n mdata-toolkit get pods
```

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
- Registry: https://amr-registry.caas.intel.com/
- Harbor project: `mdata-toolkit` (project ID 5119)
- Image: `amr-registry.caas.intel.com/mdata-toolkit/colorbox:0.2`

```shell
podman login amr-registry.caas.intel.com
podman tag colorbox:0.2 amr-registry.caas.intel.com/mdata-toolkit/colorbox:0.2
podman push amr-registry.caas.intel.com/mdata-toolkit/colorbox:0.2
```

> If the Harbor project is **Private**, also create an image pull secret in the namespace
> (using a generic/robot account) and add `imagePullSecrets` to `k8s/deployment.yaml`.
> See: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/

## Deploy to Intel CaaS (Kubernetes)
The manifests are pinned to namespace `mdata-toolkit`:
```shell
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### Verify deployment
```shell
kubectl -n mdata-toolkit get pods -l app=colorbox
kubectl -n mdata-toolkit get svc colorbox
```

### Smoke test via port-forward
```shell
kubectl -n mdata-toolkit port-forward svc/colorbox 8081:80
curl http://localhost:8081/
```

### View logs
```shell
kubectl -n mdata-toolkit logs -l app=colorbox
```

### Remove deployment
```shell
kubectl delete -f k8s/service.yaml
kubectl delete -f k8s/deployment.yaml
```

## (Optional) Expose externally
To reach the app from outside the cluster you'll additionally need:
1. A DNS alias via https://ddi.intel.com/ pointing to the cluster's load-balancer VIP.
2. A `Gateway` + `HTTPRoute` (Gateway API, `gatewayClassName: traefik`).
3. A TLS certificate (recommend cert-manager + ACME via https://certs.intel.com/).

See the CaaS Quick Start guide "Expose the Kubernetes deployment" and "Enable TLS/SSL" sections.
