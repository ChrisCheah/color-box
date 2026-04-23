# Refactor Plan: Docker to Podman / Intel CaaS

This document describes the refactoring performed to migrate the Color Box application from Docker and Cloud Foundry to Podman and Intel CaaS (Kubernetes).

## Objectives
1. Replace Docker with Podman (OCI-compliant, rootless containers)
2. Upgrade Python and all dependencies to current versions
3. Target Intel CaaS as the deployment platform
4. Remove legacy Cloud Foundry and PaaS/IaaS deployment artifacts

## Changes Made

### Python & Dependency Upgrades
| Component | Before | After |
|-----------|--------|-------|
| Python | 3.9 | 3.14 |
| Flask | >=2.2.2 | >=3.1.3 |
| Gunicorn | >=20.0.0 | >=25.3.0 |

### Files Created
| File | Purpose |
|------|---------|
| `Containerfile` | OCI-standard container definition (replaces Dockerfile). Uses `python:3.14-slim`, non-root `appuser`, exposes port 5011, runs gunicorn. |
| `.containerignore` | Excludes `env/`, `.git/`, `__pycache__/`, docs, and k8s manifests from the build context. |
| `k8s/deployment.yaml` | Kubernetes Deployment for CaaS. 1 replica, resource limits (64–128Mi RAM, 100–250m CPU), liveness/readiness probes, security hardening (runAsNonRoot, drop ALL caps, readOnlyRootFilesystem). |
| `k8s/service.yaml` | Kubernetes Service. ClusterIP type, maps port 80 to container port 5011. |
| `GettingStartedCaaS.md` | Deployment guide for Podman build/push and CaaS kubectl apply workflow. |

### Files Modified
| File | Changes |
|------|---------|
| `requirements.txt` | Updated Flask and gunicorn version constraints. |
| `runtime.txt` | Updated to `python-3.14`. |
| `README.md` | Rewrote to reflect Podman/CaaS workflow, removed Docker and Cloud Foundry references. |
| `GettingStartedLinux.md` | Updated port from 5000 to 5011, added Podman instructions, removed outdated WSL workaround. |

### Files Removed
| File | Reason |
|------|--------|
| `Dockerfile` | Replaced by `Containerfile`. |
| `manifest.yml` | Cloud Foundry manifest, no longer needed. |
| `Procfile` | Heroku/CF process file, no longer needed. |
| `GettingStartedDocker.md` | Replaced by `GettingStartedCaaS.md`. |
| `PaaSDeploymentOptions.md` | Cloud Foundry PaaS docs, no longer relevant. |
| `IaaSDeploymentOptions.md` | IaaS docs, no longer relevant. |

### Files Unchanged
| File | Reason |
|------|--------|
| `color_boxes.py` | Application code — no changes required. |
| `wsgi.py` | WSGI entry point — no changes required. |

## Container Details
- **Base image:** `python:3.14-slim`
- **Port:** 5011
- **CMD:** `gunicorn --workers=1 --bind=0.0.0.0:5011 wsgi:app`
- **Security:** Runs as non-root `appuser`, read-only root filesystem, all Linux capabilities dropped

## CaaS Deployment Target
- **Registry:** `amr-registry-pre.caas.intel.com/ditwebapp/colorbox:0.2`
- **Orchestration:** Kubernetes via `k8s/deployment.yaml` and `k8s/service.yaml`
