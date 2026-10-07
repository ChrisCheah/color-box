# Color-Box: CaaS Deployment Issue Tracker

## Issues Already Fixed (and how to recognize them)

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
