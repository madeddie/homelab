# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a GitOps-managed homelab infrastructure with:
- **3-node Kubernetes cluster** running Talos Linux (192.168.0.115, 192.168.0.120, 192.168.0.125)
- **Argo CD** for GitOps automation (watches this repo and auto-deploys)
- **Docker-Compose services** on Proxmox VM (192.168.0.50) for Home Assistant and media
- **SOPS + age** for encrypted secrets in git
- **OpenTofu** for declarative Authentik SSO configuration

## Development Environment

Load tools via any of these methods (in order of preference):
```bash
devbox shell           # Recommended - installs kubectl, helm, talosctl, sops, etc.
brew bundle            # macOS alternative
nix develop            # Nix flakes alternative
```

After loading environment:
```bash
direnv allow           # Sets KUBECONFIG and TALOSCONFIG from .envrc
kubectl get nodes      # Verify cluster access
k9s                    # Interactive cluster viewer
```

## Common Commands

### Kubernetes Cluster

```bash
# View cluster status
kubectl get nodes
kubectl get pods -A
k9s                    # Best for interactive exploration

# Access Argo CD UI (admin password in helmcharts/argo-cd/templates/argocd-secret.sops.yaml)
kubectl port-forward svc/argocd-server -n argocd 8080:443
open https://localhost:8080
```

### SOPS Encrypted Secrets

```bash
# Edit encrypted secret files
sops edit helmcharts/kube-prometheus-stack/templates/grafana-admin.sops.yaml

# Encrypt new secret (use this regex to only encrypt the data fields)
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place templates/my-secret.sops.yaml

# SOPS uses age key at ~/.config/sops/age/keys.txt
# Public key is in .sops.yaml: age13jkfzky97zmm4n738k3wy8leguhz6xy6xas9r4etnx2esyafadvqat4qve
```

### Talos Kubernetes Management

```bash
cd talos

# Generate Talos configs from talconfig.yaml
talhelper genconfig

# Check Talos cluster health
talhelper gencommand kubeconfig | sed 's/kubeconfig/health/' | bash

# Update kubeconfig
talhelper gencommand --extra-flags ./clusterconfig/kubeconfig kubeconfig | bash
```

### Docker-Compose Services (on Proxmox VM)

```bash
cd docker-compose

# Start services with SOPS-encrypted environment variables
sops exec-env secrets.sops.env 'docker compose up -d'
sops exec-env secrets.sops.env 'docker compose ps'
sops exec-env secrets.sops.env 'docker compose logs -f <service>'
```

### Authentik Configuration (OpenTofu)

```bash
cd opentofu

# All OpenTofu commands require SOPS-injected secrets
sops exec-env secrets.sops.env 'tofu plan'
sops exec-env secrets.sops.env 'tofu apply'

# State is stored encrypted in git (see backend.tf)
```

## Architecture

### GitOps Flow
```
This Git Repo → Argo CD (watches for changes) → Kubernetes Resources
                    ↓
                Helm Charts (helmcharts/*) → Deployed to K8s
                Kustomize (kustomized/*) → Deployed to K8s
                SOPS Secrets (*.sops.yaml) → Auto-decrypted by SOPS Secrets Operator
```

### Argo CD Application Structure
- **Root app**: `helmcharts/argo-cd/templates/root_app.yaml` creates the main Argo app
- **Child apps**: `argocd/apps/templates/*.yaml` define all cluster applications
- Each app points to either `helmcharts/*`, `kustomized/*`, or external Helm repos
- All apps have `syncPolicy.automated: true` - changes in git deploy automatically

### Key Infrastructure
- **MetalLB**: Load balancer IPs 192.168.0.240-250
- **Traefik**: Ingress controller with three key middlewares:
  - `default-redirect-https@kubernetescrd` - HTTP → HTTPS redirect
  - `default-lan-only@kubernetescrd` - Restrict to 192.168.0.0/24
  - `default-authentik-forward-auth@kubernetescrd` - SSO via Authentik
- **Longhorn**: Distributed storage, backs up to iDrive e2
- **CloudNativePG**: PostgreSQL operator (used by Immich)
- **SOPS Secrets Operator**: Auto-decrypts `*.sops.yaml` files in templates/

### Domains
- `*.svc.madtech.cx` - Kubernetes services (e.g., argocd, authentik, photos)
- `*.home.madtech.cx` - Docker-compose services (e.g., Home Assistant, Jellyfin)
- `*.lab.madtech.cx` - Lab/testing
- DNS managed by MikroTik router for local resolution

## Adding New Applications

### 1. Create Helm Chart
```bash
mkdir -p helmcharts/myapp/templates
# Add Chart.yaml, values.yaml, and templates
```

### 2. Add SOPS Encrypted Secrets
```yaml
# helmcharts/myapp/templates/myapp-secret.sops.yaml
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secret
type: Opaque
stringData:
  password: changeme
```

Encrypt with:
```bash
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place helmcharts/myapp/templates/myapp-secret.sops.yaml
```

### 3. Create Argo CD Application
```yaml
# argocd/apps/templates/myapp.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/madeddie/homelab.git
    targetRevision: HEAD
    path: helmcharts/myapp
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 4. Add Traefik Ingress (if needed)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: default-redirect-https@kubernetescrd,default-lan-only@kubernetescrd
spec:
  rules:
    - host: myapp.svc.madtech.cx
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp
                port:
                  number: 80
```

### 5. Deploy
Commit and push - Argo CD will automatically sync within minutes. Or manually sync via Argo UI.

## Helm Chart Structure

Most custom Helm charts follow this pattern:
```
helmcharts/myapp/
├── Chart.yaml              # Chart metadata + dependencies
├── values.yaml             # Configuration values
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    └── secret.sops.yaml    # Encrypted secrets
```

Charts with external dependencies (like `argo-cd`, `authentik`) include a `Chart.yaml` with dependencies that need `helm dependency build` before install.

## Talos Kubernetes Specifics

- **OS**: Talos Linux v1.11.3, Kubernetes v1.34.1
- **Control plane**: All 3 nodes are control planes (allowSchedulingOnControlPlanes: true)
- **Extensions**: Intel microcode, iSCSI tools, util-linux (for Longhorn)
- **Special mounts**: `/var/lib/longhorn` and `/var/lib/local-path-provisioner` mounted with `rshared`
- **Device ownership**: Containerd configured with `device_ownership_from_security_context = true` (required for KubeVirt)
- **VIP**: 192.168.0.15 for cluster API endpoint at cluster.lab.madtech.cx:6443

## Important Notes

- **Never commit unencrypted secrets** - always use SOPS
- **Argo CD manages itself** - the `argocd` application in `argocd/apps/templates/argocd.yaml` manages the Argo CD Helm chart
- **Bootstrap order**: SOPS Secrets Operator must be installed before Argo CD, as Argo needs decrypted secrets
- **Authentik is IaC**: Don't manually configure Authentik applications - edit `opentofu/authentik.tf` instead
- **Renovate enabled**: Dependency updates via GitHub PRs automatically (see renovate.json)
- **Git repository URL**: https://github.com/madeddie/homelab (referenced by all Argo apps)
