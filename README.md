# madtech homelab

This repository contains configuration and code to maintain my homelab.

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

- use talhelper to configure Talos nodes declaratively
- find a way to configure MikroTik router declaratively
- migrate software from docker-compose to k8s
- implement ArgoCD on k8s
- add LTE backup to MikroTik router
- add Raspberry Pi's to k8s cluster
- switch from Caddy to Traefik
- NUC either added to k8s cluster or remove proxmox, install VM directly on hardware to run Ansible/Terraform/bootstrap code and Home Assistant and Jellyfin
- create new git repo with local AMT Console changes
- add USB storage and simple HTTP server to MikroTik to serve PXE assets

## deprecations / cleanup
- Caddy, going to be replaced with Traefik
- MeshCentral, replaced with AMT Console
- Pi-hole, replaced with native MikroTik functionality
- Portainer, not actually used
- Sonarr, not actually used
- WireGuard Easy, replaced with native MikroTik functionality
