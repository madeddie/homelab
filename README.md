# madtech homelab

This repository contains configuration and code to maintain my homelab.

## How to initialize

### Install required tools

- Running [Devbox](https://www.jetify.com/devbox): use `devbox shell` to initialize the environment with all the required tools.
- Not running Devbox, but are using [Homebrew](https://brew.sh/): run `brew bundle` to install the required tools.

### Configure talosctl and kubectl

I'm assuming you have [Talos](https://www.talos.dev/) nodes already installed. In `talos/talconfig.yaml`
there are 3 machines, homelab{1,2,3} with IPs 192.168.0.{115,120,125}. Update this configuration
if you have a different amount of machines or use different IP addresses.

Steps:

- `cd talos`
- configure SOPS; https://budimanjojo.github.io/talhelper/latest/guides/#configuring-sops-for-talhelper
  ```
  mkdir -p "$HOME/Library/Application Support/sops/age"             # I use age for encryption
  pass homelab > "$HOME/Library/Application Support/sops/keys.txt"  # I keep secrets in [pass](https://www.passwordstore.org/)
  ```
- generate talosconfig and node configs\
  `talhelper genconfig`
- test access to talos\
  `talhelper gencommand kubeconfig | sed 's/kubeconfig/health/' | bash`  # The `health` command is not yet supported
- configure `kubectl`\
  `talhelper gencommand --extra-flags ./clusterconfig/kubeconfig kubeconfig | bash`
- test access to kubernetes\
  `kubectl get nodes`

### Bootstrap Argo CD

We'll be managing all apps in the cluster with Argo CD, even Argo CD itself, but to do this, we first need to manually install Argo CD.

```
cd helmcharts/argo-cd
helm dependency build
helm install -n argocd --create-namespace argocd .
```

Since there are some interdependencies, there might be some manual actions to take before everything works as expected.

First we'll log in to the UI.

```
kubectl port-forward service/argocd-server -n argocd 8080:443
open https://localhost:8080
```

User `admin` with the password that is bcrypt'ed in helmcharts/argo-cd/values.yaml.

We'll want to refresh the `root` Application, after that the `argocd` Application will show it's out of sync. This is because
it wasn't created with the `argocd.argoproj.io/instance` label which `argocd` itself will now add.

## Available services

### MetalLB and Traefik

The k8s cluster runs MetalLB, configured to give out IPs between 192.168.0.240 and 192.168.0.250.

Traefik was chosen as main loadbalancer and ingress service and is hardcoded to request 192.168.0.240.

## hardware

- cable modem, Arris TM1602A (supplied by Spectrum)
- router, MikroTik hAP ax3
- access point, TP-Link Archer C4000
- NUC, Beelink MINI S12 [cpu: N100, ram: 16GB, ssd: 500GB]
- 5-port switch, Netgear
- NAS, QNAP TS-253A [hdd: 3.64TB, hdd: 2.73TB, raid: 2.6TB]
- 3x 1L PC, HP EliteDesk 800 65W G3 [cpu: i5-6500@3.2GHz, ram: 32GB, ssd: 256GB]

## software

- Talos linux k8s cluster, 3 controller nodes that are also worker nodes on the 1L HP EliteDesks
  - Argo CD
  - local-path-provisioner
  - MetalLB
  - Traefik

- Proxmox on the Beelink S12, running:
    - VM with Debian Bookworm with docker-compose running:
      - [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)
      - [Console](https://github.com/device-management-toolkit/console) (with some local patches)
      - [Caddy](https://caddyserver.com/)
      - [Calibre-Web](https://github.com/janeczku/calibre-web)
      - [ESPHome](https://esphome.io/)
      - [Grafana](https://grafana.com/)
      - [Home Assistant](https://www.home-assistant.io/)
      - [homepage](https://gethomepage.dev/)
      - [Jellyfin](https://jellyfin.org/)
      - [Open Home Foundation Matter Server](https://github.com/home-assistant-libs/python-matter-server)
      - [MeshCentral](https://meshcentral.com/)
      - [Eclipse Mosquitto](https://mosquitto.org/)
      - [Pi-hole](https://pi-hole.net/)
      - [Portainer](https://www.portainer.io/)
      - [Prometheus](https://prometheus.io/)
      - [qBittorrent](https://www.qbittorrent.org/)
      - [Samba](https://github.com/dperson/samba)
      - [Sonarr](https://sonarr.tv/)
      - [WireGuard Easy](https://github.com/wg-easy/wg-easy)
      - [wyze-bridge](https://github.com/mrlt8/docker-wyze-bridge)

- MikroTik runs the folllowing services (apart from standard routing functionality):
  - Local DNS for home.madtech.cx and lab.madtech.cx
  - DHCP + PXE using [netboot.xyz](https://netboot.xyz/)
  - Wireguard VPN

## plans

- [x] use talhelper to configure Talos nodes declaratively
- [ ] find a way to configure MikroTik router declaratively
- [ ] migrate software from docker-compose to k8s
- [x] add ArgoCD
- [ ] experiment with FluxCD
- [ ] add LTE backup to MikroTik router
- [ ] add Raspberry Pi's to k8s cluster
- [x] add MetalLB
- [x] add traefik
- [x] configure traefik for *.home.madtech.cx on NUC
- [ ] switch from Caddy to Traefik for other services
- [ ] NUC either added to k8s cluster or remove proxmox, install VM directly on hardware to run Ansible/Terraform/bootstrap code and Home Assistant and Jellyfin
- [ ] create new git repo with local AMT Console changes
- [ ] add USB storage and simple HTTP server to MikroTik to serve PXE assets
- [ ] implement SAML and/or OIDC server [currently: keycloak]
- [ ] migrate services to SSO
- [ ] add oauth2-proxy for apps that don't support SAML/OIDC
- [ ] investigate use-case for argo ApplicationSets
- [ ] host own git? (forgejo)
- [ ] host own password manager? (vaultwarden?)
- [ ] add kubevirt
- [ ] add sops operator
- [ ] host own notes app? (memos: https://www.usememos.com/)
- [ ] add longhorn (storage)
- [ ] implement renovate

## deprecations / cleanup
- Caddy, going to be replaced with Traefik
- MeshCentral, replaced with AMT Console
- Pi-hole, replaced with native MikroTik functionality
- Portainer, not actually used
- Sonarr, not actually used
- WireGuard Easy, replaced with native MikroTik functionality
