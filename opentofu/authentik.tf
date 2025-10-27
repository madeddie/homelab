terraform {
  required_providers {
    authentik = {
      source = "goauthentik/authentik"
      version = "2025.10.0"
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
resource "authentik_group" "argocdadmins" {
  name = "ArgoCDAdmins"
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
resource "authentik_property_mapping_provider_scope" "group-membership" {
  name        = "Group Membership"
  scope_name  = "groups"
  expression  = "return [group.name for group in user.ak_groups.all()]"
  description = "See Which Groups you belong to"
}

# Test App (HTTP request mirror)
resource "authentik_provider_proxy" "test-app" {
  name                  = "Provider for Test App"
  external_host         = "https://test.home.madtech.cx"
  mode                  = "forward_single"
  access_token_validity = local.default_token_validity
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
}

resource "authentik_application" "test-app" {
  name              = "Test App"
  slug              = "test-app"
  protocol_provider = authentik_provider_proxy.test-app.id
}

# Home Assistant
resource "authentik_provider_proxy" "homeassistant" {
  name                  = "Provider for Home Assistant"
  external_host         = "https://assistant.home.madtech.cx"
  mode                  = "forward_single"
  access_token_validity = local.default_token_validity
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
  skip_path_regex       = "/api/.*"
}

resource "authentik_application" "homeassistant" {
  name              = "Home Assistant"
  slug              = "homeassistant"
  protocol_provider = authentik_provider_proxy.homeassistant.id
}

# Calibre Web
resource "authentik_provider_proxy" "calibre-web" {
  name                  = "Provider for Calibre Web"
  external_host         = "https://calibre.home.madtech.cx"
  mode                  = "forward_single"
  access_token_validity = local.default_token_validity
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
}

resource "authentik_application" "calibre-web" {
  name              = "Calibre Web"
  slug              = "calibre-web"
  protocol_provider = authentik_provider_proxy.calibre-web.id
}

# qBittorrent
resource "authentik_provider_proxy" "qbittorrent" {
  name                  = "Provider for qBittorrent"
  external_host         = "https://torrent.home.madtech.cx"
  mode                  = "forward_single"
  access_token_validity = local.default_token_validity
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
}

resource "authentik_application" "qbittorrent" {
  name              = "qBittorrent"
  slug              = "qbittorrent"
  protocol_provider = authentik_provider_proxy.qbittorrent.id
}

# Prometheus
resource "authentik_provider_proxy" "prometheus" {
  name                  = "Provider for Prometheus"
  external_host         = "https://prometheus.home.madtech.cx"
  mode                  = "forward_single"
  access_token_validity = local.default_token_validity
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
}

resource "authentik_application" "prometheus" {
  name              = "Prometheus"
  slug              = "prometheus"
  protocol_provider = authentik_provider_proxy.prometheus.id
}

# Alertmanager
resource "authentik_provider_proxy" "alertmanager" {
  name                  = "Provider for Alertmanager"
  external_host         = "https://alertmanager.home.madtech.cx"
  mode                  = "forward_single"
  access_token_validity = local.default_token_validity
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
}

resource "authentik_application" "alertmanager" {
  name              = "Alertmanager"
  slug              = "alertmanager"
  protocol_provider = authentik_provider_proxy.alertmanager.id
}

# ESPHome
resource "authentik_provider_proxy" "esphome" {
  name                  = "Provider for ESPHome"
  external_host         = "https://esphome.home.madtech.cx"
  mode                  = "forward_single"
  access_token_validity = local.default_token_validity
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
}

resource "authentik_application" "esphome" {
  name              = "ESPHome"
  slug              = "esphome"
  protocol_provider = authentik_provider_proxy.esphome.id
}

# Caddy Proxy Outpost
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

resource "authentik_application" "argocd" {
  name              = "ArgoCD"
  slug              = "argocd"
  protocol_provider = authentik_provider_oauth2.argocd.id
}

# Jellyfin
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

resource "authentik_application" "jellyfin" {
  name              = "Jellyfin"
  slug              = "jellyfin"
  protocol_provider = authentik_provider_oauth2.jellyfin.id
}

# Proxmox
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

resource "authentik_application" "proxmox" {
  name              = "Proxmox"
  slug              = "proxmox"
  protocol_provider = authentik_provider_oauth2.proxmox.id
}

# Immich
resource "authentik_provider_oauth2" "immich" {
  name               = "Provider for Immich"
  client_id          = "immich"
  client_type        = "public"
  signing_key        = data.authentik_certificate_key_pair.generated.id
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow  = data.authentik_flow.default-invalidation-flow.id
  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url           = "app.immich:///oauth-callback",
    },
    {
      matching_mode = "strict",
      url           = "https://photos.svc.madtech.cx/auth/login",
    },
    {
      matching_mode = "strict",
      url           = "https://photos.svc.madtech.cx/user-settings",
    },
    {
      matching_mode = "strict",
      url           = "http://localhost:2283/auth/login",
    }
  ]
  property_mappings = data.authentik_property_mapping_provider_scope.default-scopes.ids
}

resource "authentik_application" "immich" {
  name              = "Immich"
  slug              = "immich"
  protocol_provider = authentik_provider_oauth2.immich.id
}
