# Color-Box: End-to-End CaaS Deployment Guide

> **Audience**: Developer or AI agent deploying `color-box` (Flask + gunicorn) to **Intel CaaS** (Rancher-managed Kubernetes + Harbor registry) on Windows + Podman + WSL.
>
> **Goal**: Reproducible deployment without re-discovering the gotchas already solved in this repo.
>
> **Last validated**: April 2026, cluster `amr-fm-compute-cluster`, namespace `mdata-toolkit`, registry project `mdata-toolkit` (Harbor ID 5119).

---

## TL;DR — Happy Path Commands

```powershell
# 0. One-time tooling
winget install -e --id Kubernetes.kubectl --accept-source-agreements --accept-package-agreements
winget install -e --id RedHat.Podman                  # if not already installed

# 1. Per-shell environment (CRITICAL — see Issue #2 and #3)
$env:KUBECONFIG = "$PWD\amr-fm-compute-cluster.yaml"
$env:NO_PROXY   = "localhost,127.0.0.1,.intel.com,10.0.0.0/8"
$env:no_proxy   = $env:NO_PROXY

# 2. Start podman VM and configure its proxy bypass (see Issue #4)
podman machine start
podman machine ssh "systemctl --user set-environment NO_PROXY='localhost,127.0.0.1,.intel.com,10.0.0.0/8' no_proxy='localhost,127.0.0.1,.intel.com,10.0.0.0/8'"

# 3. Build, tag, push (see Issue #5 for --tls-verify=false)
podman build -t colorbox:0.2 .
podman tag  colorbox:0.2 amr-registry.caas.intel.com/mdata-toolkit/colorbox:0.2
podman login amr-registry.caas.intel.com
podman push --tls-verify=false amr-registry.caas.intel.com/mdata-toolkit/colorbox:0.2

# 4. Configure kubectl (see Issue #1 for stale CA workaround)
kubectl config set-cluster amr-fm-compute-cluster --insecure-skip-tls-verify=true

# 5. Deploy
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl -n mdata-toolkit rollout status deployment/colorbox --timeout=120s

# 6. Smoke-test
kubectl -n mdata-toolkit port-forward svc/colorbox 8081:80   # leave running
# In another shell:
curl http://127.0.0.1:8081/
curl -X POST http://127.0.0.1:8081/box/red
curl http://127.0.0.1:8081/box

# 7. Run automated tests (unit + E2E)
$env:COLORBOX_BASE_URL = "http://127.0.0.1:8081"
.\env\Scripts\python.exe -m pytest tests/ -v
```

---

## 1. Prerequisites

### 1.1 Intel access

| Item | How to obtain |
|---|---|
| Valid **IAPM ID** | Required to create CaaS projects |
| AGS entitlement: **CaaS Users** | https://ags.intel.com/ → search "CaaS Users" |
| AGS entitlement: **CaaS AD Users** *(only for ITS-classified projects)* | Same as above |
| Harbor registry project (`mdata-toolkit`) | Request via https://goto.intel.com/caasrequest |
| Rancher project / namespace (`mdata-toolkit`) | Request via https://goto.intel.com/caasrequest |
| Intel proxies configured | `setx HTTP_PROXY "http://proxy-dmz.intel.com:912"` etc. |

### 1.2 Local tooling

| Tool | Notes |
|---|---|
| **Podman** ≥ 5.x | With WSL backend on Windows. `podman machine init && podman machine start`. |
| **kubectl** | `winget install Kubernetes.kubectl`. After install, **restart shell or refresh PATH** (see Issue #6). |
| **Python** ≥ 3.11 | Use `py` launcher on Windows. |
| **Kubeconfig file** | Download from Rancher: https://amr.caas.intel.com/ → cluster → "Download Kubeconfig". Save to repo root as `amr-fm-compute-cluster.yaml`. **Already gitignored** — contains a bearer token. |

---

## 2. Configuration That MUST Be Right

These are the items that, if wrong, will produce the cryptic failures listed in §4.

### 2.1 Image registry & namespace

Manifests in `k8s/` are pinned to:

- **Registry**: `amr-registry.caas.intel.com` (production registry, *not* `-pre`)
- **Project**: `mdata-toolkit` (Harbor ID 5119)
- **Namespace**: `mdata-toolkit`
- **Image tag**: `0.2`

If you change any of these, update [k8s/deployment.yaml](../k8s/deployment.yaml) and [k8s/service.yaml](../k8s/service.yaml).

### 2.2 Harbor project visibility

The `mdata-toolkit` Harbor project is **Public**, so the cluster can pull anonymously. **No `imagePullSecrets` needed.**

If your project is **Private**, add a `docker-registry` secret and reference it:

```powershell
kubectl -n mdata-toolkit create secret docker-registry harbor-creds `
  --docker-server=amr-registry.caas.intel.com `
  --docker-username=<robot-account> `
  --docker-password=<robot-token>
```

```yaml
# k8s/deployment.yaml — add under spec.template.spec
imagePullSecrets:
  - name: harbor-creds
```

### 2.3 Container security (PSS-restricted)

The cluster enforces Pod Security Standards. The Containerfile and Deployment must agree on **all** of:

| Requirement | Where set |
|---|---|
| Run as **non-root with numeric UID** | `Containerfile`: `RUN useradd -r -u 10001 appuser` + `USER 10001`<br>`deployment.yaml`: `runAsNonRoot: true`, `runAsUser: 10001` |
| `readOnlyRootFilesystem: true` | `deployment.yaml` containers section |
| Writable `/tmp` for gunicorn workers | `deployment.yaml`: `emptyDir` volume mounted at `/tmp` |
| `allowPrivilegeEscalation: false`, drop ALL capabilities | `deployment.yaml` |

> Why: gunicorn writes worker temp files; with `readOnlyRootFilesystem` and no `/tmp` volume, workers crash on startup (Issue #7). Without a numeric UID, the kubelet rejects the pod with "image has non-numeric user" (Issue #8).

### 2.4 Proxy bypass (the silent killer)

Both kubectl (on Windows) and podman (in its WSL VM) must bypass the Intel DMZ proxy for `*.intel.com`. Without this you get HTML "Access Denied" pages from `pgproxy*` (Issue #2 and #4).

**On Windows shell** (must set in EVERY new shell unless you `setx` it permanently):
```powershell
$env:NO_PROXY = "localhost,127.0.0.1,.intel.com,10.0.0.0/8"
$env:no_proxy = $env:NO_PROXY
```

**Inside the podman WSL VM** (one-time per VM session):
```powershell
podman machine ssh "systemctl --user set-environment NO_PROXY='localhost,127.0.0.1,.intel.com,10.0.0.0/8' no_proxy='localhost,127.0.0.1,.intel.com,10.0.0.0/8'"
```

To make the Windows setting permanent:
```powershell
setx NO_PROXY "localhost,127.0.0.1,.intel.com,10.0.0.0/8"
```

---

## 3. Step-by-Step Deployment

### Step 1 — Verify prerequisites

```powershell
podman --version          # 5.x+
kubectl version --client  # 1.30+
py -V                     # 3.11+
Test-Path .\amr-fm-compute-cluster.yaml   # True
```

If `kubectl` is "not recognized" right after `winget install`, you must **start a new PowerShell window** OR refresh PATH:

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

### Step 2 — Configure shell environment

```powershell
$env:KUBECONFIG = "$PWD\amr-fm-compute-cluster.yaml"
$env:NO_PROXY   = "localhost,127.0.0.1,.intel.com,10.0.0.0/8"
$env:no_proxy   = $env:NO_PROXY
```

### Step 3 — Patch kubeconfig CA (one-time per kubeconfig)

The CA chain embedded in Rancher-issued kubeconfigs is sometimes stale (intermediate expired in 2023). The cluster cert itself is fine — Windows trusts the current Intel root via the system store. Tell kubectl to skip CA verification for this cluster:

```powershell
kubectl config set-cluster amr-fm-compute-cluster --insecure-skip-tls-verify=true
```

> **Acceptable risk**: traffic stays on Intel internal network and the bearer token is still required. Re-download the kubeconfig from Rancher every ~30 days (token expiry).

### Step 4 — Verify cluster access

```powershell
kubectl -n mdata-toolkit get pods
# Expected (first time): "No resources found in mdata-toolkit namespace."
```

If you see an HTML page or "Access Denied" / `pgproxy`: your `NO_PROXY` isn't set (Step 2).

### Step 5 — Start podman and configure its proxy

```powershell
podman machine start
podman machine ssh "systemctl --user set-environment NO_PROXY='localhost,127.0.0.1,.intel.com,10.0.0.0/8' no_proxy='localhost,127.0.0.1,.intel.com,10.0.0.0/8'"
podman machine ssh "env | grep -i no_proxy"   # verify
```

### Step 6 — Build, tag, push

```powershell
podman build -t colorbox:0.2 .
podman tag  localhost/colorbox:0.2 amr-registry.caas.intel.com/mdata-toolkit/colorbox:0.2
podman login amr-registry.caas.intel.com
# → username: your IDSID (or AD\IDSID for ITS projects)
# → password: your Intel password
podman push --tls-verify=false amr-registry.caas.intel.com/mdata-toolkit/colorbox:0.2
```

> Why `--tls-verify=false`: Harbor presents the same Intel-internal cert chain that the WSL VM doesn't trust by default. The push happens over a Bearer-authenticated session inside the Intel network — acceptable risk.

### Step 7 — Apply manifests and wait for rollout

```powershell
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl -n mdata-toolkit rollout status deployment/colorbox --timeout=120s
kubectl -n mdata-toolkit get pods,svc -l app=colorbox
```

Expected:
```
NAME                            READY   STATUS    RESTARTS   AGE
pod/colorbox-xxxxxxxxxx-xxxxx   1/1     Running   0          30s

NAME               TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
service/colorbox   ClusterIP   10.43.x.x     <none>        80/TCP    35s
```

### Step 8 — Smoke test

```powershell
# Terminal A — leave running
kubectl -n mdata-toolkit port-forward svc/colorbox 8081:80

# Terminal B
curl http://127.0.0.1:8081/                       # → "Hello stranger!"
curl -X POST http://127.0.0.1:8081/box/red        # → "Empty box 'red' created."
curl http://127.0.0.1:8081/box                    # → HTML list
```

### Step 9 — Automated tests

```powershell
# First run: create venv + install deps
py -m venv env
.\env\Scripts\python.exe -m pip install --upgrade pip
.\env\Scripts\python.exe -m pip install -r requirements-dev.txt

# Unit tests (no cluster needed)
.\env\Scripts\python.exe -m pytest tests/test_color_boxes_unit.py -v

# E2E tests against deployment (port-forward must be active)
$env:COLORBOX_BASE_URL = "http://127.0.0.1:8081"
.\env\Scripts\python.exe -m pytest tests/ -v
# Expected: 15 passed
```

---

## 4. Issues Already Fixed (and how to recognize them)

This is the canonical list of failures encountered during initial deployment, with the **symptom**, **root cause**, and **fix** that's already in this repo. If you see a symptom, the fix is already applied — but if you re-create the artifact (kubeconfig, podman VM, venv), you may need to re-apply the workaround.

### Issue #1 — kubectl: `x509: certificate signed by unknown authority`

**Symptom**:
```
Unable to connect to the server: tls: failed to verify certificate:
x509: certificate signed by unknown authority
```

**Cause**: Embedded `certificate-authority-data` in the kubeconfig contains an Intel intermediate CA that has expired. kubectl uses only the kubeconfig CA when present, ignoring the OS trust store.

**Fix**:
```powershell
kubectl config set-cluster amr-fm-compute-cluster --insecure-skip-tls-verify=true
```
Re-apply after each fresh kubeconfig download.

### Issue #2 — kubectl returns HTML "Access Denied" / `pgproxy`

**Symptom**: kubectl output is a giant HTML page mentioning `pgproxy103`, `proxy-dmz.intel.com`, "Access Denied".

**Cause**: PowerShell inherited the user's `HTTP_PROXY=proxy-dmz.intel.com:912`. The DMZ proxy refuses to forward to Intel-internal hosts like `amr.caas.intel.com`.

**Fix**: Set `NO_PROXY` before running kubectl (Step 2). Use `setx` for permanence.

### Issue #3 — Outdated bearer token (`Unauthorized` / HTML login page)

**Symptom**: `Error from server (Unauthorized)` or HTML page after fixing CA + proxy.

**Cause**: Rancher-issued tokens expire (~30 days).

**Fix**: Re-download kubeconfig from Rancher and replace `amr-fm-compute-cluster.yaml`.

### Issue #4 — `podman push` returns proxy block page

**Symptom**:
```
StatusCode: 403, "<!-- IE friendly error message walkround. ..."
```
during `podman push`.

**Cause**: The podman WSL VM has `HTTPS_PROXY` set globally (via `/etc/environment` or systemd) but `NO_PROXY` is empty. So pushes to `*.caas.intel.com` go through the DMZ proxy.

**Fix**:
```powershell
podman machine ssh "systemctl --user set-environment NO_PROXY='localhost,127.0.0.1,.intel.com,10.0.0.0/8' no_proxy='localhost,127.0.0.1,.intel.com,10.0.0.0/8'"
```
Re-apply after each `podman machine init` or full restart.

### Issue #5 — `podman push`: x509 unknown authority on Harbor

**Symptom**:
```
pinging container registry amr-registry.caas.intel.com:
tls: failed to verify certificate: x509: certificate signed by unknown authority
```

**Cause**: WSL VM doesn't have the Intel Root CA installed.

**Fix**: Use `--tls-verify=false` on push commands. Long-term fix would be to bake Intel Root CA into the podman machine.

### Issue #6 — `kubectl` not recognized after `winget install`

**Symptom**:
```
The term 'kubectl' is not recognized as a name of a cmdlet, function, script file, or executable program.
```

**Cause**: `winget` updates the persisted PATH but not the current shell's `$env:Path`.

**Fix**: Restart PowerShell, or refresh PATH in the current shell:
```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

### Issue #7 — Pod CrashLoopBackOff: `No usable temporary directory found`

**Symptom**: gunicorn traceback in pod logs:
```
FileNotFoundError: [Errno 2] No usable temporary directory found in
    ['/tmp', '/var/tmp', '/usr/tmp', '/app']
```

**Cause**: `readOnlyRootFilesystem: true` in the pod securityContext blocks gunicorn from creating worker temp files.

**Fix** (already in [k8s/deployment.yaml](../k8s/deployment.yaml)):
```yaml
volumeMounts:
  - name: tmp
    mountPath: /tmp
volumes:
  - name: tmp
    emptyDir: {}
```

### Issue #8 — Pod `CreateContainerConfigError`: non-numeric user

**Symptom**:
```
Error: container has runAsNonRoot and image has non-numeric user (appuser),
cannot verify user is non-root
```

**Cause**: `USER appuser` in Dockerfile resolves to a name, not a UID. Cluster's PSS enforcement can't verify non-root from a name alone.

**Fix** (already in [Containerfile](../Containerfile) and [k8s/deployment.yaml](../k8s/deployment.yaml)):
```dockerfile
# Containerfile
RUN useradd -r -u 10001 appuser
USER 10001
```
```yaml
# deployment.yaml — pod securityContext
runAsNonRoot: true
runAsUser: 10001
```

### Issue #9 — Stale Python venv

**Symptom**:
```
No Python at '"C:\Program Files\Python311\python.exe'
```
when activating `env\Scripts\Activate.ps1`.

**Cause**: Venv was created with a Python that has since been uninstalled.

**Fix**: Recreate the venv with current Python:
```powershell
Remove-Item -Recurse -Force env
py -m venv env
.\env\Scripts\python.exe -m pip install -r requirements-dev.txt
```

---

## 5. Post-Deployment Verification Checklist

| Check | Command | Expected |
|---|---|---|
| Pod Running | `kubectl -n mdata-toolkit get pods -l app=colorbox` | `1/1 Running` |
| Service exists | `kubectl -n mdata-toolkit get svc colorbox` | `ClusterIP 10.43.x.x:80` |
| Endpoints populated | `kubectl -n mdata-toolkit get endpoints colorbox` | non-empty IPs |
| Probes succeeding | `kubectl -n mdata-toolkit describe pod -l app=colorbox` | no `Unhealthy` events |
| Logs clean | `kubectl -n mdata-toolkit logs -l app=colorbox` | gunicorn startup, no tracebacks |
| HTTP 200 on `/` | (port-forward) `curl http://127.0.0.1:8081/` | `Hello stranger!` |
| All tests pass | `pytest tests/ -v` (with `COLORBOX_BASE_URL` set) | `15 passed` |

---

## 6. Next Steps

The current deployment is **internal-only** (ClusterIP). To expose externally and harden for production:

### 6.1 External access via Gateway API

Per [CaaS Quick Start](https://github.com/intel-innersource/applications.infrastructure.caas.caas-demo) "Expose the Kubernetes deployment":

1. **Identify cluster's load-balancer VIP** for `amr-fm-compute-cluster` from the [Shared Clusters page](https://intel.sharepoint.com/sites/caascustomercommunity/SitePages/CaaS-Rancher-and-Registry-Available-Environments.aspx).
2. **Request a DNS alias** at https://ddi.intel.com/ → `New DDI Request` → `Alias in .intel.com` (e.g. `colorbox.intel.com`) targeting the VIP.
3. Create `k8s/gateway.yaml`:
   ```yaml
   apiVersion: gateway.networking.k8s.io/v1
   kind: Gateway
   metadata:
     name: colorbox-gateway
     namespace: mdata-toolkit
   spec:
     gatewayClassName: traefik
     listeners:
       - name: http
         port: 9080            # 80 after Ingress→Gateway migration completes
         protocol: HTTP
   ---
   apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: colorbox-route
     namespace: mdata-toolkit
   spec:
     parentRefs:
       - name: colorbox-gateway
     hostnames:
       - colorbox.intel.com
     rules:
       - matches:
           - path: { type: PathPrefix, value: / }
         backendRefs:
           - name: colorbox
             port: 80
   ```
4. Apply: `kubectl apply -f k8s/gateway.yaml`

### 6.2 TLS via cert-manager + ACME (Sectigo)

1. Onboard IAP for ACME at https://intel.service-now.com/ (one-time).
2. Get **EAB Key ID** and **HMAC Secret** from https://certs.intel.com/aperture (Policy Tree → IAP → ACME tab).
3. Create `k8s/cert.yaml` with `Issuer` + `Certificate` (template in CaaS guide).
4. Reference the cert in the Gateway `listeners[https].tls.certificateRefs`.
5. Add HTTP→HTTPS redirect rule to `HTTPRoute`.

### 6.3 Production hardening

- [ ] Switch base image to **CaaS cache registry** to avoid DockerHub rate limits: `cache-registry.caas.intel.com/cache/library/python:3.14-slim`
- [ ] Bake **Intel trust chain** into the image (`amr-registry.caas.intel.com/intel-hub/intel-trust-chain`) so outbound HTTPS to Intel services works
- [ ] Replace `--tls-verify=false` and `--insecure-skip-tls-verify` by installing the Intel Root CA into the WSL VM and (if needed) refreshing the kubeconfig
- [ ] Add `HorizontalPodAutoscaler` (CPU-based) and bump `replicas`
- [ ] Add **Prometheus metrics** endpoint (Flask middleware) and a `ServiceMonitor`
- [ ] Add **structured JSON logging** for Loki/Splunk ingestion
- [ ] Replace in-memory `boxes = {}` with persistent storage (current state is lost on every restart — see [color_boxes.py](../color_boxes.py))
- [ ] Set up a **GitHub Actions / Jenkins** pipeline: lint → unit tests → build → push → `kubectl apply`
- [ ] Use a **robot account** for registry pulls instead of personal credentials
- [ ] Rotate the bearer token in the kubeconfig regularly; consider a CI service account with limited RBAC

### 6.4 Observability quick wins

```powershell
# Pod logs (live)
kubectl -n mdata-toolkit logs -f -l app=colorbox

# Resource usage
kubectl -n mdata-toolkit top pods

# Events
kubectl -n mdata-toolkit get events --sort-by=.lastTimestamp
```

---

## 7. Reference: Repo Layout

| Path | Purpose |
|---|---|
| [color_boxes.py](../color_boxes.py) | Flask app |
| [wsgi.py](../wsgi.py) | gunicorn entry point |
| [Containerfile](../Containerfile) | Container build (numeric UID 10001, slim Python) |
| [requirements.txt](../requirements.txt) | Runtime deps |
| [requirements-dev.txt](../requirements-dev.txt) | Adds pytest |
| [k8s/deployment.yaml](../k8s/deployment.yaml) | Deployment with PSS-restricted security context, `/tmp` emptyDir, probes |
| [k8s/service.yaml](../k8s/service.yaml) | ClusterIP service on port 80 → 5011 |
| [tests/test_color_boxes_unit.py](../tests/test_color_boxes_unit.py) | 11 unit tests via Flask test client |
| [tests/test_deployed_api.py](../tests/test_deployed_api.py) | 4 E2E tests via `COLORBOX_BASE_URL` |
| [GettingStartedCaaS.md](../GettingStartedCaaS.md) | Concise quick-start (companion to this doc) |
| `amr-fm-compute-cluster.yaml` | Kubeconfig (gitignored — contains bearer token) |

---

## 8. Quick Reference: Common Commands

```powershell
# Re-deploy after image change
podman build -t colorbox:0.2 . ; `
podman push --tls-verify=false amr-registry.caas.intel.com/mdata-toolkit/colorbox:0.2 ; `
kubectl -n mdata-toolkit rollout restart deployment/colorbox ; `
kubectl -n mdata-toolkit rollout status deployment/colorbox --timeout=120s

# Tear down
kubectl delete -f k8s/service.yaml
kubectl delete -f k8s/deployment.yaml

# Debug a failing pod
kubectl -n mdata-toolkit describe pod -l app=colorbox
kubectl -n mdata-toolkit logs -l app=colorbox --previous   # last crashed instance

# Exec into pod (read-only FS — limited)
kubectl -n mdata-toolkit exec -it deploy/colorbox -- sh
```
