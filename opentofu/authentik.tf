terraform {
  required_providers {
    authentik = {
      source = "goauthentik/authentik"
      version = "2025.4.0"
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

## Home Assistant
#
#import {
#  to = authentik_provider_proxy.homeassistant
#  id = 10
#}
#resource "authentik_provider_proxy" "homeassistant" {
#  name                  = "Provider for Home Assistant"
#  external_host         = "https://assistant.home.madtech.cx"
#  mode                  = "forward_single"
#  access_token_validity = local.default_token_validity
#  authorization_flow    = data.authentik_flow.default-authorization-flow.id
#  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
#}
#
#import {
#  to = authentik_application.homeassistant
#  id = "homeassistant"
#}
#
#resource "authentik_application" "homeassistant" {
#  name              = "Home Assistant"
#  slug              = "homeassistant"
#  protocol_provider = authentik_provider_proxy.homeassistant.id
#}

# Caddy Proxy Outpost
import {
  to = authentik_outpost.home-caddy-proxy
  id = "800bd561-776f-43dc-92d0-77f0b02316a7"
}

resource "authentik_outpost" "home-caddy-proxy" {
  name = "home-caddy-proxy"
  # TODO replace hardcoded IDs with imported applications
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
