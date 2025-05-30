# madtech homelab

This repository contains configuration and code to maintain my homelab.

## How to initialize

### Install required tools

- Running [Devbox](https://www.jetify.com/devbox): use `devbox shell` to
  initialize the environment with all the required tools.
- Not running Devbox, but are using [Homebrew](https://brew.sh/): run
  `brew bundle` to install the required tools.

### Configure talosctl and kubectl

I'm assuming you have [Talos](https://www.talos.dev/) nodes already installed.
In `talos/talconfig.yaml` there are 3 machines, homelab{1,2,3} with IPs
192.168.0.{115,120,125}. Update this configuration if you have a different
amount of machines or use different IP addresses.

Steps:

- `cd talos`
- configure SOPS;
  https://budimanjojo.github.io/talhelper/latest/guides/#configuring-sops-for-talhelper
  ```
  mkdir -p "$HOME/.config/sops/age"             # I use age for encryption
  pass homelab_talos > "$HOME/.config/sops/keys.txt"  # I keep secrets in [pass](https://www.passwordstore.org/)
  ```
- generate talosconfig and node configs\
  `talhelper genconfig`
- test access to talos\
  `talhelper gencommand kubeconfig | sed 's/kubeconfig/health/' | bash` # The
  `health` command is not yet supported
- configure `kubectl`\
  `talhelper gencommand --extra-flags ./clusterconfig/kubeconfig kubeconfig | bash`
- test access to kubernetes\
  `kubectl get nodes`

### Bootstrap SOPS and Argo CD

We'll be managing all apps (including Argo CD itself) in the cluster with Argo
CD and managing secrets using SOPS secrets operator, which allows storing the
secrets, encrypted, in git.

To start we first need to manually create the main decryption key Secret, using
the same `age` key we used for the Talos config:

```
kubectl create namespace sops
kubectl -n sops create secret generic sops-age-key-file --from-file="$HOME/.config/sops/age/keys.txt"
helm upgrade --install sops sops/sops-secrets-operator --namespace sops --set "secretsAsFiles[0].mountPath=/etc/sops-age-key-file,secretsAsFiles[0].name=sops-age
-key-file,secretsAsFiles[0].secretName=sops-age-key-file,extraEnv[0].name=SOPS_AGE_KEY_FILE,extraEnv[0].value=/etc/sops-age-key-file/keys.txt"
```

and install Argo CD (just once):

```
cd helmcharts/argo-cd
helm repo add argo https://argoproj.github.io/argo-helm
helm dependency build
helm install -n argocd --create-namespace argocd .
```

Since there are some interdependencies, there might be some manual actions to
take before everything works as expected.

Let's log in to the UI.

```
kubectl port-forward service/argocd-server -n argocd 8080:443
open https://localhost:8080
```

User `admin` with the password that is bcrypt'ed in
helmcharts/argo-cd/values.yaml.

We'll want to refresh the `root` Application, after that the `argocd`
Application will show it's out of sync. This is because it wasn't created with
the `argocd.argoproj.io/instance` label which `argocd` itself will add if we
press Sync and then Synchronize.

### Bootstrap docker-compose

The `docker-compose/` folder contains the configuration of the docker compose setup on the NUC.
A prerequisite for setup is installing and configuring SOPS as descibed below, but instead of `pass homelab_talos` we use `pass homelab_compose`.

After checking out the repo, run:

`sops exec-env secrets.sops.env 'docker compose up -d'`

This should bring up all the containers and feed them their "secret" ENV vars.

TODO: I have not yet put all application configuration in version control.

Also, some of the data will be in backups (DBs and other binary blobs). The restoration procedure needs to be described.

### Configure Authentik using OpenTofu

To configure Authentik declaratively, I've chosen to use OpenTofu, aka the more opensource version
of Terraform.

I'm storing the TF state in git in encrypted form. The passphrase is also stored, separately encrypted
with SOPS.

To execute OpenTofu we'll need to run it encapsulated by SOPS like this:

```
cd opentofu
sops exec-env sops.secrets.env 'tofu plan'
```

Where `plan` is the OpenTofu command to execute. This will inject environment variables with the
secrets used by OpenTofu.

## Available services

### MetalLB and Traefik

The k8s cluster runs MetalLB, configured to give out IPs between 192.168.0.240
and 192.168.0.250.

Traefik was chosen as main loadbalancer and ingress service and is hardcoded to
request 192.168.0.240.

### SOPS secrets operator

We can add Secrets to our git repo safely since they can be encrypted using
SOPS.

Create a SopsSecret CR encapsulating whichever Secret's you want, encrypt it
with `sops` and commit it to the repo. After creating the CR with
`kubectl apply -f ...` or adding it to an Argo CD Application (through Helm or
Kustomize), the SOPS secrets operator will decrypt the values and create the k8s
Secret objects.

## hardware

- cable modem, Arris TM1602A (supplied by Spectrum)
- router, MikroTik hAP ax3
- access point, TP-Link Archer C4000
- NUC, Beelink MINI S12 [cpu: N100, ram: 16GB, ssd: 500GB]
- 5-port switch, Netgear
- NAS, QNAP TS-253A [hdd: 3.64TB, hdd: 2.73TB, raid: 2.6TB]
- 3x 1L PC, HP EliteDesk 800 65W G3 [cpu: i5-6500@3.2GHz, ram: 32GB, ssd: 256GB]

## software

- Talos linux k8s cluster, 3 controller nodes that are also worker nodes on the
  1L HP EliteDesks
  - Argo CD
  - Authentik
  - KubeVirt
  - local-path-provisioner
  - Longhorn
  - MetalLB
  - metrics-server + Kubelet Serving Certificate Approver
  - SOPS secrets operator
  - Traefik

- Proxmox on the Beelink S12, running:
  - VM with Debian Bookworm with docker-compose running:
    - [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)
    - [Authentik Proxy outpost](https://docs.goauthentik.io/docs/add-secure-apps/outposts/manual-deploy-docker-compose)
    - [Console](https://github.com/device-management-toolkit/console) (with some
      local patches)
    - [Caddy](https://caddyserver.com/)
    - [Calibre-Web](https://github.com/janeczku/calibre-web)
    - [ESPHome](https://esphome.io/)
    - [Grafana](https://grafana.com/)
    - [http-https-echo](https://github.com/mendhak/docker-http-https-echo)
    - [Home Assistant](https://www.home-assistant.io/)
    - [homepage](https://gethomepage.dev/)
    - [Jellyfin](https://jellyfin.org/)
    - [Open Home Foundation Matter Server](https://github.com/home-assistant-libs/python-matter-server)
    - [Eclipse Mosquitto](https://mosquitto.org/)
    - [Prometheus](https://prometheus.io/)
    - [qBittorrent](https://www.qbittorrent.org/)
    - [Samba](https://github.com/dockur/samba)
    - [wyze-bridge](https://github.com/mrlt8/docker-wyze-bridge)

- MikroTik runs the folllowing services (apart from standard routing
  functionality):
  - Local DNS for home.madtech.cx, svc.madtech.cx and lab.madtech.cx
  - DHCP + PXE using [netboot.xyz](https://netboot.xyz/)
  - Wireguard VPN

## plans

- [x] use talhelper to configure Talos nodes declaratively
- [ ] find a way to configure MikroTik router declaratively
- [ ] regularly backup mikrotik config (ssh mikrotik /export > backup.rsc)
- [-] migrate software from docker-compose to k8s
- [x] add ArgoCD
- [ ] experiment with FluxCD
- [ ] add LTE backup to MikroTik router
- [ ] add Raspberry Pi's to k8s cluster
- [x] add MetalLB
- [x] add traefik
- [x] configure traefik for *.home.madtech.cx on NUC
- [ ] ~~switch from Caddy to Traefik for other services~~ (Will stick with caddy
      on docker and traefik in k8s)
- [ ] NUC either added to k8s cluster or remove proxmox, install VM directly on
      hardware to run Ansible/Terraform/bootstrap code and Home Assistant and
      Jellyfin
- [ ] create new git repo with local AMT Console changes
- [ ] add USB storage and simple HTTP server to MikroTik to serve PXE assets
- [x] implement SAML and/or OIDC server (~~keycloak~~authentik)
- [x] test keycloak
- [x] implement Authentik
- [x] migrate services to SSO
  - [x] ArgoCD (OIDC + PKCE)
  - [x] Home Assistant (using https://github.com/BeryJu/hass-auth-header)
  - [x] Jellyfin (using https://github.com/9p4/jellyfin-plugin-sso)
  - [x] Calibre-Web (using built-in Reverse Proxy Authentication)
  - [x] Prometheus/Grafana/Alertmanager (just behind auth, no integration, so no users in the apps)
  - [x] qBittorrent (using forward auth and disabling auth on local subnet)
  - [x] Proxmox
- [x] ~~add oauth2-proxy for apps that don't support SAML/OIDC~~ using Traefik
      built-in forward auth
- [ ] investigate use-case for argo ApplicationSets
- [ ] host own git? (forgejo)
- [ ] host own password manager? (vaultwarden? I'm using passwordstore.org for now)
- [x] add kubevirt
- [x] add sops operator
- [ ] ~~host own notes app? (memos: https://www.usememos.com/)~~ (using Markor +
      git)
- [x] add longhorn (storage)
- [x] implement renovate
- [x] add metrics-server
- [ ] try running a k8s service needing a specific USB device (for home assistant + zigbee)
- [ ] try running a k8s service using video decoding hardware (for jellyfin)
- [ ] implement hardware watchdog on talos nodes
      (https://www.talos.dev/v1.9/advanced/watchdog/)
- [x] set up basic github page for project using Jekyll
- [ ] set up github actions to copy README and create Changelog for the project
      site
- [ ] implement paperless-ngx
- [ ] replace NAS? (raspberry pi 5 + raspberry pi penta hat + 4x 2.5 SATA SSD)
- [ ] implement PV on NAS (Samba? NFS? iSCSI?)
- [ ] implement backups
- [ ] backup services
  - [ ] Authentik https://docs.goauthentik.io/docs/sys-mgmt/ops/backup-restore
  - [ ] ArgoCD? https://argo-cd.readthedocs.io/en/stable/operator-manual/disaster_recovery/
  - [ ] longhorn? https://longhorn.io/docs/1.8.1/snapshots-and-backups/backup-and-restore/set-backup-target/
  - [ ] Home Assistant https://www.home-assistant.io/integrations/backup/
  - [ ] Jellyfin? https://jellyfin.org/docs/general/administration/backup-and-restore/
  - [ ] Calibre-Web https://github.com/janeczku/calibre-web/issues/733
- [ ] implement local image storage (move from google photos?)
- [x] instructions are missing installing SOPS helm chart before argocd
- [ ] add sops helm chart with included values to simplify bootstrap
      instructions
- [ ] switch or duplicate use of devbox into nix shell (I use nix-darwin and
      nix-on-droid now)
- [x] find a way to declaratively configure authentik
- [ ] figure out social login with authentik and google/github
- [x] Caddy is behind Traefik from outside traffic. This breaks SSL cert
      renewal. Fix. (now using ACME with dns auth)
- [x] auto create traefik namespace
- [x] label longhorn namespace pod-security.kubernetes.io/enforce=privileged
- [ ] implement cert-manager
- [x] implement letsencrypt dns verification in traefik
- [x] implement letsencrypt dns verification in caddy
- [x] describe restoration procedure for all apps with binary blob backups
- [ ] put docker-compose apps config in version control
  - [x] caddy
  - [ ] alertmanager
  - [ ] amt_console
  - [ ] esphome
  - [ ] grafana
  - [ ] home-assistant
  - [ ] jellyfin
  - [ ] matter-server?
  - [ ] mosquitto
  - [ ] prometheus
  - [ ] qbittorrent
- [ ] test Authelia (should be more light weight than Authentik)
- [ ] test signoz (opensource datadog competitor)
- [/] use opentofu to configure authentik
- [ ] test spinning up virgin authentik with terraform (check https://docs.goauthentik.io/docs/install-config/automated-install)
- [ ] add (forwarding) SMTP server for app notifications
- [ ] try loki (logging)
- [ ] try kubero
- [ ] try openfaas

Legend:

[-] task started, but barely </br>
[/] task about halfway done </br>
[x] task done </br>

## deprecations / cleanup

- ~~MeshCentral, replaced with AMT Console~~
- ~~Pi-hole, replaced with native MikroTik functionality~~
- ~~Portainer, not actually used~~
- ~~Sonarr, not actually used~~
- ~~WireGuard Easy, replaced with native MikroTik functionality~~
