terraform {
  required_providers {
    authentik = {
      source = "goauthentik/authentik"
      version = "2025.6.0"
    }
  }
}

locals {
  default_token_validity = "hours=24"
}

provider "authentik" {
  url   = "https://authentik.svc.madtech.cx"
}

data "authentik_flow" "default-authorization-flow" {
  slug = "default-provider-authorization-explicit-consent"
}

data "authentik_flow" "default-invalidation-flow" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

data "authentik_property_mapping_provider_scope" "default-scopes" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile"
  ]
}

data "authentik_group" "admins" {
  name = "authentik Admins"
}

# Users and groups
import {
  to = authentik_group.argocdadmins
  id = "e249624d-2f37-4471-9d8a-35aaf4c957a9"
}

resource "authentik_group" "argocdadmins" {
  name = "ArgoCDAdmins"
}

import {
  to = authentik_user.madeddie
  id = 7
}

resource "authentik_user" "madeddie" {
  username = "madeddie"
  name     = "Edwin Hermans"
  email    = "edwin@madtech.cx"
  groups   = [
    authentik_group.argocdadmins.id,
    data.authentik_group.admins.id
  ]
}

# Group Membership Property Mapping (mostly used by ArgoCD)
import {
  to = authentik_property_mapping_provider_scope.group-membership
  id = "9178bc15-57d1-4d06-96c6-b2c648becc79"
}

resource "authentik_property_mapping_provider_scope" "group-membership" {
  name        = "Group Membership"
  scope_name  = "groups"
  expression  = "return [group.name for group in user.ak_groups.all()]"
  description = "See Which Groups you belong to"
}

# Test App (HTTP request mirror)
import {
  to = authentik_provider_proxy.test-app
  id = 35
}

resource "authentik_provider_proxy" "test-app" {
  name                  = "Provider for Test App"
  external_host         = "https://test.home.madtech.cx"
  mode                  = "forward_single"
  access_token_validity = local.default_token_validity
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
}

import {
  to = authentik_application.test-app
  id = "test-app"
}

resource "authentik_application" "test-app" {
  name              = "Test App"
  slug              = "test-app"
  protocol_provider = authentik_provider_proxy.test-app.id
}

# Home Assistant
import {
  to = authentik_provider_proxy.homeassistant
  id = 10
}

resource "authentik_provider_proxy" "homeassistant" {
  name                  = "Provider for Home Assistant"
  external_host         = "https://assistant.home.madtech.cx"
  mode                  = "forward_single"
  access_token_validity = local.default_token_validity
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
  skip_path_regex       = "/api/.*"
}

import {
  to = authentik_application.homeassistant
  id = "homeassistant"
}

resource "authentik_application" "homeassistant" {
  name              = "Home Assistant"
  slug              = "homeassistant"
  protocol_provider = authentik_provider_proxy.homeassistant.id
}

# Calibre Web
import {
  to = authentik_provider_proxy.calibre-web
  id = 12
}

resource "authentik_provider_proxy" "calibre-web" {
  name                  = "Provider for Calibre Web"
  external_host         = "https://calibre.home.madtech.cx"
  mode                  = "forward_single"
  access_token_validity = local.default_token_validity
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
}

import {
  to = authentik_application.calibre-web
  id = "calibre-web"
}

resource "authentik_application" "calibre-web" {
  name              = "Calibre Web"
  slug              = "calibre-web"
  protocol_provider = authentik_provider_proxy.calibre-web.id
}

# qBittorrent
import {
  to = authentik_provider_proxy.qbittorrent
  id = 14
}

resource "authentik_provider_proxy" "qbittorrent" {
  name                  = "Provider for qBittorrent"
  external_host         = "https://torrent.home.madtech.cx"
  mode                  = "forward_single"
  access_token_validity = local.default_token_validity
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
}

import {
  to = authentik_application.qbittorrent
  id = "qbittorrent"
}

resource "authentik_application" "qbittorrent" {
  name              = "qBittorrent"
  slug              = "qbittorrent"
  protocol_provider = authentik_provider_proxy.qbittorrent.id
}

# Prometheus
import {
  to = authentik_provider_proxy.prometheus
  id = 24
}

resource "authentik_provider_proxy" "prometheus" {
  name                  = "Provider for Prometheus"
  external_host         = "https://prometheus.home.madtech.cx"
  mode                  = "forward_single"
  access_token_validity = local.default_token_validity
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
}

import {
  to = authentik_application.prometheus
  id = "prometheus"
}

resource "authentik_application" "prometheus" {
  name              = "Prometheus"
  slug              = "prometheus"
  protocol_provider = authentik_provider_proxy.prometheus.id
}

# Alertmanager
import {
  to = authentik_provider_proxy.alertmanager
  id = 30
}

resource "authentik_provider_proxy" "alertmanager" {
  name                  = "Provider for Alertmanager"
  external_host         = "https://alertmanager.home.madtech.cx"
  mode                  = "forward_single"
  access_token_validity = local.default_token_validity
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
}

import {
  to = authentik_application.alertmanager
  id = "alertmanager"
}

resource "authentik_application" "alertmanager" {
  name              = "Alertmanager"
  slug              = "alertmanager"
  protocol_provider = authentik_provider_proxy.alertmanager.id
}

# ESPHome
import {
  to = authentik_provider_proxy.esphome
  id = 34
}

resource "authentik_provider_proxy" "esphome" {
  name                  = "Provider for ESPHome"
  external_host         = "https://esphome.home.madtech.cx"
  mode                  = "forward_single"
  access_token_validity = local.default_token_validity
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
}

import {
  to = authentik_application.esphome
  id = "esphome"
}

resource "authentik_application" "esphome" {
  name              = "ESPHome"
  slug              = "esphome"
  protocol_provider = authentik_provider_proxy.esphome.id
}

# Caddy Proxy Outpost
import {
  to = authentik_outpost.home-caddy-proxy
  id = "800bd561-776f-43dc-92d0-77f0b02316a7"
}

resource "authentik_outpost" "home-caddy-proxy" {
  name = "home-caddy-proxy"
  protocol_providers = [
    authentik_provider_proxy.homeassistant.id,
    authentik_provider_proxy.calibre-web.id,
    authentik_provider_proxy.qbittorrent.id,
    authentik_provider_proxy.prometheus.id,
    authentik_provider_proxy.alertmanager.id,
    authentik_provider_proxy.esphome.id,
    authentik_provider_proxy.test-app.id
  ]
}

# Oauth2 Apps

# ArgoCD
import {
  to = authentik_provider_oauth2.argocd
  id = 2
}

resource "authentik_provider_oauth2" "argocd" {
  name               = "Provider for ArgoCD"
  client_id          = "argocd"
  client_type        = "public"
  signing_key        = data.authentik_certificate_key_pair.generated.id
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow  = data.authentik_flow.default-invalidation-flow.id
  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url           = "http://localhost:8085/auth/callback",
    },
    {
      matching_mode = "strict",
      url           = "https://argocd.svc.madtech.cx/auth/callback",
    },
    {
      matching_mode = "strict",
      url           = "https://argocd.svc.madtech.cx/pkce/verify",
    }
  ]
  property_mappings = data.authentik_property_mapping_provider_scope.default-scopes.ids
}

import {
  to = authentik_application.argocd
  id = "argocd"
}

resource "authentik_application" "argocd" {
  name              = "ArgoCD"
  slug              = "argocd"
  protocol_provider = authentik_provider_oauth2.argocd.id
}

# Jellyfin
import {
  to = authentik_provider_oauth2.jellyfin
  id = 18
}

resource "authentik_provider_oauth2" "jellyfin" {
  name               = "Provider for Jellyfin"
  client_id          = "jellyfin"
  client_type        = "confidential"
  signing_key        = data.authentik_certificate_key_pair.generated.id
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow  = data.authentik_flow.default-invalidation-flow.id
  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url           = "https://jellyfin.home.madtech.cx/sso/OID/redirect/Authentik",
    }
  ]
  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default-scopes.ids,
    [authentik_property_mapping_provider_scope.group-membership.id]
  )
}

import {
  to = authentik_application.jellyfin
  id = "jellyfin"
}

resource "authentik_application" "jellyfin" {
  name              = "Jellyfin"
  slug              = "jellyfin"
  protocol_provider = authentik_provider_oauth2.jellyfin.id
}

# Proxmox
import {
  to = authentik_provider_oauth2.proxmox
  id = 22
}

resource "authentik_provider_oauth2" "proxmox" {
  name               = "Provider for Proxmox"
  client_id          = "proxmox"
  client_type        = "confidential"
  signing_key        = data.authentik_certificate_key_pair.generated.id
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow  = data.authentik_flow.default-invalidation-flow.id
  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url           = "https://192.168.0.50:8006",
    }
  ]
  property_mappings = data.authentik_property_mapping_provider_scope.default-scopes.ids
}

import {
  to = authentik_application.proxmox
  id = "proxmox"
}

resource "authentik_application" "proxmox" {
  name              = "Proxmox"
  slug              = "proxmox"
  protocol_provider = authentik_provider_oauth2.proxmox.id
}
