# madtech homelab

A GitOps-managed homelab infrastructure running Kubernetes and Docker services for smart home automation, media management, and self-hosted applications.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Hardware](#hardware)
- [Quick Start](#quick-start)
- [Deployment Guide](#deployment-guide)
  - [1. Install Tools](#1-install-tools)
  - [2. Configure Talos Kubernetes](#2-configure-talos-kubernetes)
  - [3. Bootstrap SOPS & Argo CD](#3-bootstrap-sops--argo-cd)
  - [4. Configure Docker-Compose](#4-configure-docker-compose)
  - [5. Configure Authentik (OpenTofu)](#5-configure-authentik-opentofu)
- [Deployed Services](#deployed-services)
- [Adding Applications](#adding-applications)
- [Roadmap](#roadmap)

---

## Overview

This repository uses **Infrastructure as Code (IaC)** principles to declaratively manage:

- **3-node Kubernetes cluster** (Talos Linux)
- **GitOps automation** (Argo CD)
- **Encrypted secrets in git** (SOPS with age encryption)
- **Docker-compose services** (Proxmox VM)
- **SSO/Authentication** (Authentik)

**Key Technologies:**
- Kubernetes orchestration via Talos Linux
- GitOps with Argo CD
- Helm charts & Kustomize for deployments
- SOPS for secret management
- OpenTofu for infrastructure state
- MetalLB + Traefik for networking
- Longhorn for distributed storage
- CloudNativePG for PostgreSQL
- Prometheus + Grafana for monitoring

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│  External Network (192.168.0.0/24)                   │
│  ├─ MikroTik Router (DNS, DHCP, WireGuard VPN)       │
│  └─ TP-Link Archer C4000 Access Point                │
└──────────────────────────────────────────────────────┘
                         │
    ┌────────────────────┴────────────────────┐
    │                                         │
┌───▼─────────────────────────────┐  ┌────────▼──────────────────┐
│  Kubernetes Cluster (Talos)     │  │  Proxmox VM (Beelink S12) │
│  ├─ 3x HP EliteDesk 800 G3      │  │  └─ Docker-Compose        │
│  ├─ MetalLB (192.168.0.240-250) │  │     ├─ Home Assistant     │
│  ├─ Traefik (Ingress)           │  │     ├─ Jellyfin           │
│  ├─ Argo CD (GitOps)            │  │     ├─ ESPHome            │
│  ├─ Authentik (SSO)             │  │     ├─ Mosquitto          │
│  ├─ Longhorn (Storage)          │  │     ├─ qBittorrent        │
│  ├─ Prometheus Stack            │  │     ├─ Calibre-Web        │
│  ├─ Immich (Photos)             │  │     └─ More...            │
│  ├─ cert-manager                │  │                           │
│  ├─ akri                        │  │                           │
│  ├─ zigbee2mqtt                 │  │                           │
│  └─ KubeVirt                    │  │                           │
└─────────────────────────────────┘  └───────────────────────────┘
                         │
              ┌──────────▼──────────┐
              │  QNAP TS-253A NAS   │
              │  └─ 2.6TB RAID      │
              │  └─ Backups         │
              └─────────────────────┘
```

**Data Flow:**
```
Git Repository (this repo)
    ↓
Argo CD (watches for changes)
    ↓
├─ Helm Charts → Kubernetes Deployments
├─ Kustomize → Kubernetes Resources
└─ SOPS Encrypted Secrets → Decrypted at runtime
    ↓
OpenTofu → Authentik Configuration (IaC)
```

---

## Hardware

| Component | Details |
|-----------|---------|
| **Internet** | Arris TM1602A Cable Modem (Spectrum) |
| **Router** | MikroTik hAP ax3 |
| **Access Point** | TP-Link Archer C4000 |
| **K8s Nodes** | 3x HP EliteDesk 800 65W G3<br>└─ i5-6500 @ 3.2GHz, 32GB RAM, 256GB SSD |
| **Docker Host** | Beelink MINI S12 (Proxmox)<br>└─ Intel N100, 16GB RAM, 500GB SSD |
| **Storage** | QNAP TS-253A NAS<br>└─ 3.64TB + 2.73TB HDDs, 2.6TB usable (RAID) |
| **Network** | Netgear 5-port switch |

---

## Quick Start

```bash
# 1. Load development environment
devbox shell  # or: brew bundle, or: nix develop

# 2. Allow direnv to set KUBECONFIG & TALOSCONFIG
direnv allow

# 3. Check cluster status
kubectl get nodes
k9s  # Interactive cluster viewer

# 4. View Argo CD applications
kubectl port-forward svc/argocd-server -n argocd 8080:443
open https://localhost:8080  # user: admin, password in helmcharts/argo-cd/templates/argocd-secret.sops.yaml (if you can't remember, bcrypt a new password in there)

# 5. Edit encrypted secrets
sops edit helmcharts/kube-prometheus-stack/templates/grafana-admin.sops.yaml
```

---

## Deployment Guide

### 1. Install Tools

Choose one of the following methods:

**Option A: Devbox (recommended)**
```bash
devbox shell
```

**Option B: Homebrew (macOS)**
```bash
brew bundle
```

**Option C: Nix Flakes**
```bash
nix develop
```

### 2. Configure Talos Kubernetes

Assumes you have Talos nodes already installed at:
- `homelab1` → 192.168.0.115
- `homelab2` → 192.168.0.120
- `homelab3` → 192.168.0.125

Update `talos/talconfig.yaml` if your IPs differ.

#### Steps:

```bash
cd talos

# Configure SOPS encryption (one-time setup)
mkdir -p "$HOME/.config/sops/age"
pass homelab_talos > "$HOME/.config/sops/age/keys.txt"  # Or manually create age key

# Generate Talos configs
talhelper genconfig

# Check Talos health
talhelper gencommand kubeconfig | sed 's/kubeconfig/health/' | bash

# Configure kubectl
talhelper gencommand --extra-flags ./clusterconfig/kubeconfig kubeconfig | bash

# Verify cluster
kubectl get nodes
```

### 3. Bootstrap SOPS & Argo CD

#### Install SOPS Secrets Operator

```bash
# Create namespace and age key secret
kubectl create namespace sops
kubectl -n sops create secret generic sops-age-key-file \
  --from-file="$HOME/.config/sops/age/keys.txt"

# Install SOPS operator
helm upgrade --install sops sops/sops-secrets-operator \
  --namespace sops \
  --set "secretsAsFiles[0].mountPath=/etc/sops-age-key-file" \
  --set "secretsAsFiles[0].name=sops-age-key-file" \
  --set "secretsAsFiles[0].secretName=sops-age-key-file" \
  --set "extraEnv[0].name=SOPS_AGE_KEY_FILE" \
  --set "extraEnv[0].value=/etc/sops-age-key-file/keys.txt"
```

#### Install Argo CD

```bash
cd helmcharts/argo-cd
helm repo add argo https://argoproj.github.io/argo-helm
helm dependency build
helm install -n argocd --create-namespace argocd .
```

#### Access Argo CD UI

```bash
kubectl port-forward service/argocd-server -n argocd 8080:443
open https://localhost:8080
```

- **User:** `admin`
- **Password:** Bcrypt'ed in `helmcharts/argo-cd/templates/argocd-secret.sops.yaml`

**Post-Install:**
1. Refresh the `root` Application
2. Sync the `argocd` Application (adds required labels)

### 4. Configure Docker-Compose

On the Proxmox NUC (Beelink S12):

```bash
cd docker-compose

# Configure SOPS (one-time)
mkdir -p "$HOME/.config/sops/age"
pass homelab_compose > "$HOME/.config/sops/age/keys.txt"

# Start services with encrypted env vars
sops exec-env secrets.sops.env 'docker compose up -d'
```

**Note:** Application configs and database restoration procedures are still being documented.

### 5. Configure Authentik (OpenTofu)

Authentik is configured declaratively using OpenTofu (Terraform). The state is stored encrypted in git.

```bash
cd opentofu

# Run OpenTofu commands with SOPS-injected secrets
sops exec-env secrets.sops.env 'tofu plan'
sops exec-env secrets.sops.env 'tofu apply'
```

---

## Deployed Services

### Kubernetes Cluster

| Service | Purpose |
|---------|---------|
| **Argo CD** | GitOps continuous delivery |
| **Authentik** | SSO/OIDC authentication provider |
| **Traefik** | Ingress controller & reverse proxy |
| **MetalLB** | Load balancer (192.168.0.240-250) |
| **cert-manager** | Automatic TLS certificate management |
| **Longhorn** | Distributed block storage |
| **CloudNativePG** | PostgreSQL operator |
| **Prometheus Stack** | Monitoring (Prometheus, Grafana, AlertManager) |
| **Immich** | Self-hosted photo management |
| **KubeVirt** | Virtual machine management |
| **Akri** | USB device discovery & sharing |
| **external-dns** | Dynamic DNS management |
| **SOPS Secrets Operator** | Encrypted secret management |
| **metrics-server** | Kubernetes resource metrics |
| **Node Feature Discovery** | Hardware capability detection |
| **local-path-provisioner** | Local volume provisioning |
| **go-httpbin** | HTTP debugging utility |
| **akri** | Hardware device resource manager |
| **zigbee2mqtt** | Zigbee to MQTT gateway |

### Docker-Compose (Proxmox VM)

| Service | Purpose |
|---------|---------|
| **Home Assistant** | Smart home automation hub |
| **ESPHome** | ESP32/ESP8266 device management |
| **Mosquitto** | MQTT broker |
| **Matter Server** | Matter protocol support |
| **wyze-bridge** | Wyze camera integration |
| **Jellyfin** | Media streaming server |
| **qBittorrent** | Torrent client |
| **Calibre-Web** | Ebook library management |
| **Prometheus** | Metrics collection |
| **Grafana** | Visualization dashboards |
| **AlertManager** | Alert routing |
| **Caddy** | Web server & reverse proxy |
| **Authentik Proxy** | Forward authentication outpost |
| **Console** | Device management toolkit |
| **Samba** | File sharing |
| **http-https-echo** | HTTP debugging |

### MikroTik Router Services

- **Local DNS:** `home.madtech.cx`, `svc.madtech.cx`, `lab.madtech.cx`
- **DHCP:** Network address assignment
- **PXE Boot:** Using [netboot.xyz](https://netboot.xyz/)
- **WireGuard VPN:** Remote access

---

## Adding Applications

### Creating Traefik Ingress

Add annotations to your Ingress resource:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    # Redirect HTTP to HTTPS
    traefik.ingress.kubernetes.io/router.middlewares: default-redirect-https@kubernetescrd

    # Restrict to LAN
    traefik.ingress.kubernetes.io/router.middlewares: default-lan-only@kubernetescrd

    # Forward authentication (Authentik SSO)
    traefik.ingress.kubernetes.io/router.middlewares: default-authentik-forward-auth@kubernetescrd
```

### Adding SOPS Encrypted Secrets

1. Create a Secret YAML in your Helm chart's `templates/` folder:

```yaml
# templates/my-secret.sops.yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
stringData:
  username: admin
  password: changeme
```

2. Encrypt the secret values:

```bash
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place templates/my-secret.sops.yaml
```

3. The SOPS Secrets Operator will automatically decrypt it when deployed.

### Adding Argo CD Applications

Create a new file in `argocd/apps/templates/`:

```yaml
# argocd/apps/templates/my-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/homelab
    targetRevision: main
    path: helmcharts/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

---

## Roadmap

### Infrastructure
- [ ] Find way to configure MikroTik router declaratively
- [ ] Regularly backup MikroTik config (`ssh mikrotik /export > backup.rsc`)
- [ ] Add LTE backup to MikroTik router
- [ ] Add Raspberry Pi nodes to K8s cluster
- [ ] Add USB storage + HTTP server to MikroTik for PXE assets
- [ ] Implement hardware watchdog on Talos nodes

### Storage & Backups
- [ ] Investigate Velero for K8s backup
- [ ] Implement PV on NAS (Samba/NFS/iSCSI)
- [ ] Consider replacing NAS (Raspberry Pi 5 + Penta HAT + SSDs?)
- [ ] Backup all services:
  - [ ] Authentik (use cngpg backup to S3/idrive)
  - [ ] Argo CD
  - [x] Longhorn (to iDrive e2)
  - [ ] Home Assistant
  - [ ] Jellyfin
  - [ ] Calibre-Web
  - [ ] Immich (DB + media)

### Applications & Services
- [ ] Host own git (Forgejo)
- [ ] Host password manager (Vaultwarden)
- [ ] Implement Paperless-NGX (document management)
- [ ] Add forwarding SMTP server for notifications
- [ ] Try Loki (log aggregation)
- [ ] Try SigNoz (Datadog alternative)
- [ ] Try Kubero (PaaS)
- [ ] Try OpenFaaS (serverless)
- [ ] Test Authelia (lightweight auth alternative)

### Hardware & Devices
- [x] Implement Node Feature Discovery
- [x] Implement Akri for USB device detection (Zigbee stick)
- [ ] Implement Intel GPU device plugin (Jellyfin transcoding)
- [x] Test K8s service with USB device (Home Assistant + Zigbee)
- [ ] Test K8s service with video hardware decoding (Jellyfin)

### Networking & DNS
- [x] Implement external-dns
- [ ] Configure external-dns with Hurricane Electric & MikroTik
- [ ] Configure cert-manager ACME issuer

### Migrations & Improvements
- [ ] Migrate remaining docker-compose apps to K8s
- [x] Migrate Authentik PostgreSQL to CNPG
- [ ] Investigate Redis/Valkey operator
- [ ] Test social login with Authentik (Google/GitHub)
- [ ] Investigate Argo ApplicationSets use cases
- [ ] Put docker-compose app configs in version control
  - [x] Caddy
  - [ ] AlertManager, ESPHome, Grafana, Home Assistant
  - [ ] Jellyfin, Mosquitto, Prometheus, qBittorrent

### Documentation
- [ ] Document restoration procedures for all apps
- [x] Add Jekyll GitHub Pages site
- [ ] Set up GitHub Actions for README & Changelog automation

### Completed
- [x] Use talhelper for declarative Talos configuration
- [x] Add Argo CD for GitOps
- [x] Add MetalLB & Traefik
- [x] Implement OIDC server (Authentik, replacing Keycloak)
- [x] Migrate services to SSO (Argo CD, Home Assistant, Jellyfin, etc.)
- [x] Add KubeVirt for VM management
- [x] Add SOPS Secrets Operator
- [x] Add Longhorn for distributed storage
- [x] Implement Renovate for dependency updates
- [x] Add metrics-server
- [x] Install CloudNativePG for Immich
- [x] Implement Immich (Google Photos replacement)
- [x] Switch to Devbox/Nix for dev environment
- [x] Declaratively configure Authentik with OpenTofu
- [x] Implement cert-manager
- [x] Implement Let's Encrypt DNS verification (Traefik & Caddy)
- [x] Set up iDrive e2 for backups
- [x] Configure Longhorn backups to iDrive e2

### Deprecated
- ~~MeshCentral~~ (replaced with AMT Console)
- ~~Pi-hole~~ (replaced with MikroTik DNS)
- ~~Portainer~~ (not used)
- ~~Sonarr~~ (not used)
- ~~WireGuard Easy~~ (replaced with MikroTik WireGuard)
- ~~Keycloak~~ (replaced with Authentik)

**Legend:**
`[-]` Started | `[/]` Halfway | `[x]` Done

---

## Contributing

This is a personal homelab project, but feel free to open issues for questions or suggestions!

## License

[MIT License](https://github.com/madeddie/homelab#MIT-1-ov-file)

This project is for personal use. Feel free to reference or adapt for your own homelab.
