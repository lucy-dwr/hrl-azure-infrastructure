resource "azurerm_cdn_frontdoor_profile" "apps" {
  name                = local.front_door_profile_name
  resource_group_name = azurerm_resource_group.apps.name
  sku_name            = var.front_door_sku_name
  tags                = local.common_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "apps" {
  name                     = local.front_door_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.apps.id
  tags                     = local.common_tags
}

resource "azurerm_cdn_frontdoor_origin_group" "restoration_map" {
  name                     = "og-restoration-map"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.apps.id

  health_probe {
    interval_in_seconds = 100
    path                = "/"
    protocol            = "Https"
    request_type        = "GET"
  }

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 4
    successful_samples_required        = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "restoration_map" {
  name                          = "origin-restoration-map"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.restoration_map.id
  enabled                       = true

  certificate_name_check_enabled = true
  host_name                      = azurerm_static_web_app.restoration_map.default_host_name
  origin_host_header             = azurerm_static_web_app.restoration_map.default_host_name
  http_port                      = 80
  https_port                     = 443
  priority                       = 1
  weight                         = 1000
}

resource "azurerm_cdn_frontdoor_rule_set" "restoration_map" {
  name                     = "rsrestorationmap"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.apps.id
}

# Canonicalize the public application entry point before applying the prefix
# rewrite below. This keeps relative browser URLs predictable.
resource "azurerm_cdn_frontdoor_rule" "restoration_map_trailing_slash" {
  name                      = "canonicalizerestorationmap"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.restoration_map.id
  order                     = 1
  behavior_on_match         = "Stop"

  conditions {
    request_uri_condition {
      operator     = "Equal"
      match_values = ["/restoration-map"]
    }
  }

  actions {
    url_redirect_action {
      redirect_type        = "PermanentRedirect"
      redirect_protocol    = "Https"
      destination_hostname = "{hostname}"
      destination_path     = "/restoration-map/"
    }
  }
}

# The Static Web App origin is hosted at its root. The browser sees the
# /restoration-map/ prefix, while Front Door removes it before forwarding.
resource "azurerm_cdn_frontdoor_rule" "restoration_map_prefix_rewrite" {
  name                      = "rewriterestorationmapprefix"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.restoration_map.id
  order                     = 2
  behavior_on_match         = "Continue"

  conditions {
    request_uri_condition {
      operator     = "BeginsWith"
      match_values = ["/restoration-map/"]
    }
  }

  actions {
    url_rewrite_action {
      source_pattern          = "/restoration-map/"
      destination             = "/"
      preserve_unmatched_path = true
    }
  }
}

resource "azurerm_cdn_frontdoor_route" "restoration_map" {
  name                          = "route-restoration-map"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.apps.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.restoration_map.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.restoration_map.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.restoration_map.id]

  patterns_to_match      = ["/restoration-map", "/restoration-map/*"]
  supported_protocols    = ["Http", "Https"]
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  link_to_default_domain = true

  cdn_frontdoor_custom_domain_ids = var.custom_domain_enabled ? [azurerm_cdn_frontdoor_custom_domain.hrl[0].id] : []
}

resource "azurerm_cdn_frontdoor_firewall_policy" "apps" {
  name                = local.front_door_waf_name
  resource_group_name = azurerm_resource_group.apps.name
  sku_name            = var.front_door_sku_name
  enabled             = true
  mode                = var.front_door_waf_mode

  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }

  tags = local.common_tags
}

resource "azurerm_cdn_frontdoor_security_policy" "apps" {
  name                     = "sp-${local.project}-${var.environment}-waf"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.apps.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.apps.id

      association {
        patterns_to_match = ["/*"]

        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.apps.id
        }

        dynamic "domain" {
          for_each = var.custom_domain_enabled ? azurerm_cdn_frontdoor_custom_domain.hrl : []

          content {
            cdn_frontdoor_domain_id = domain.value.id
          }
        }
      }
    }
  }
}

# DTS owns the water.ca.gov DNS zone. Terraform creates no DNS record here.
# Enabling this resource exposes the TXT validation token for a DTS request;
# Azure retains the custom domain while its validation is pending.
resource "azurerm_cdn_frontdoor_custom_domain" "hrl" {
  count = var.custom_domain_enabled ? 1 : 0

  name                     = "hrl-water-ca-gov"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.apps.id
  host_name                = var.custom_domain_hostname

  tls {
    certificate_type = "ManagedCertificate"
  }
}
