# CaaS Rancher and Registry Available Environments
Source: [CaaS Rancher and Registry Available Environments](https://intel.sharepoint.com/sites/caascustomercommunity/SitePages/CaaS-Rancher-and-Registry-Available-Environments.aspx#shared-clusters-per-classification)

## Rancher Environments
| Region | DC Location | Network | Rancher URL |
|--------|------------|---------|------------|
| AMR PRE | Santa Clara | Internal | https://amr-pre.caas.intel.com |
| GER PRE | Israel | Internal | https://ger-pre.caas.intel.com |
| AMR | Santa Clara | Internal | https://amr.caas.intel.com |
| GER | Israel | Internal | https://ger.caas.intel.com |
| GAR | Bangalore | Internal | https://gar.caas.intel.com |
| AMR | Folsom | SIZ | https://amr-siz.caas.intel.com |
| AMR2 | Folsom | Internal | https://amr2.caas.intel.com |

## Pre-Production (Intel Confidential - Linux)
| DC Location | Cluster Name | Rancher URL | Traefik Ingress | Nginx Ingress | Wide IP | Firewall Group | Conjur ID |
|-------------|-------------|-------------|-----------------|---------------|---------|----------------|-----------|
| Santa Clara (AMR) | amr-pre-compute-cluster | https://amr-pre.caas.intel.com | lbauto-10-3-89-207.cps.intel.com | lbauto-10-3-89-26.cps.intel.com | caas-amr-pre-compute-workers.iglb.intel.com | g_gpb_pre_sc_caas | k8s_amr-pre-compute-cluster_19635 |
| Folsom (AMR) | amr-pre-fm-compute-cluster | https://amr-pre.caas.intel.com | lbauto-10-1-16-74.cps.intel.com | lbauto-10-1-16-9.cps.intel.com | caas-amr-pre-fm-compute-workers.iglb.intel.com | g_gpb_pre_fm_caas | k8s_amr-pre-fm-compute-cluster_19635 |
| Israel (GER) | ger-pre-is-compute-cluster | https://ger-pre.caas.intel.com | lbauto-10-184-69-202.cps.intel.com | lbauto-10-184-69-11.cps.intel.com | caas-ger-pre-compute-workers.iglb.intel.com | g_gpb_pre_is_caas | k8s_ger-pre-is-compute-cluster_19635 |

## Pre-Production (Windows)
| DC Location | Cluster Name | Rancher URL | Traefik Ingress | Nginx Ingress | Firewall Group | Conjur ID |
|-------------|-------------|-------------|-----------------|---------------|----------------|-----------|
| Folsom (AMR) | amr-pre-rke2-win-compute-cluster | https://amr-pre.caas.intel.com | lbauto-10-18-89-71.cps.intel.com | lbauto-10-18-89-103.cps.intel.com | g_gpb_pre_fm_win_caas | k8s_amr-pre-rke2-win-compute-cluster_19635 |

## Production Internal (Linux)
| DC Location | Cluster Name | Rancher URL | Traefik Ingress | Nginx Ingress | Wide IP | Firewall Group | Conjur ID |
|-------------|-------------|-------------|-----------------|---------------|---------|----------------|-----------|
| Santa Clara (AMR) | amr-compute-cluster | https://amr.caas.intel.com | lbauto-10-3-89-209.cps.intel.com | lbauto-10-3-89-37.cps.intel.com | caas-amr-prod-compute-workers.iglb.intel.com | g_gpb_sc_caas | k8s_amr-compute-cluster_19635 |
| Folsom (AMR) | amr-fm-compute-cluster | https://amr.caas.intel.com | lbauto-10-4-168-198.cps.intel.com | lbauto-10-4-168-96.cps.intel.com | caas-amr-fm-prod-compute-workers.iglb.intel.com | g_gpb_fm_caas | k8s_amr-fm-compute-cluster_19635 |
| Israel (GER) | ger-is-compute-cluster | https://ger.caas.intel.com | lbauto-10-184-69-205.cps.intel.com | lbauto-10-184-69-166.cps.intel.com | caas-ger-is-prod-compute-workers.iglb.intel.com | g_gpb_is_caas | k8s_ger-is-compute-cluster_19635 |
| Bangalore (GAR) | gar-compute-cluster | https://gar.caas.intel.com | lbauto-10-223-157-12.cps.intel.com | lbauto-10-223-157-228.cps.intel.com | caas-gar-prod-compute-workers.iglb.intel.com | g_gpb_gar_caas | k8s_gar-compute-cluster_19635 |
| Penang (GAR) | gar-pg-compute-cluster | https://gar.caas.intel.com | lbauto-172-30-179-187.cps.intel.com | lbauto-172-30-179-117.cps.intel.com | caas-gar-pg-prod-compute-workers.iglb.intel.com | g_gpb_pg_caas | k8s_gar-pg-compute-cluster_19635 |

## Registry (Intel Confidential)
| DC Location | Network | Environment | URL | Firewall Group |
|-------------|---------|-------------|-----|----------------|
| Santa Clara (AMR) | Internal | Pre-Prod | https://amr-registry-pre.caas.intel.com | g_siz_CAAS-REGISTRY-AMR-PRE |
| Israel (GER) | Internal | Pre-Prod | https://ger-is-registry-pre.caas.intel.com | g_siz_CAAS-REGISTRY-GER-PRE |
| Santa Clara (AMR) | Internal | Prod | https://amr-registry.caas.intel.com | g_siz_CAAS-REGISTRY-AMR |
| Israel (GER) | Internal | Prod | https://ger-is-registry.caas.intel.com | g_siz_CAAS-REGISTRY-GER |
| Bangalore (GAR) | Internal | Prod | https://gar-registry.caas.intel.com | g_siz_CAAS-REGISTRY-GAR |
| Folsom (AMR) | External | Prod | https://amr-fmext-registry.caas.intel.com | g_siz_CAAS-REGISTRY-AMR |

## Registry (Intel Top Secret)
| DC Location | Network | Environment | URL |
|-------------|---------|-------------|-----|
| Folsom (AMR) | Internal | Prod | https://amr-its-registry.caas.intel.com |
| Chandler (AMR) | Internal | Prod | https://amr-its-ch-registry.caas.intel.com |

