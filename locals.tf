locals {
  # certificates
  trustAnchorsPEM = var.external_identity_issuer ? var.trust_anchors_pem_value : file("${path.module}/certs/proxy_trust_anchor.pem")
  scheme          = var.external_identity_issuer ? "kubernetes.io/tls" : "linkerd.io/tls"

  validating_webhook_ca_bundle = var.sp_validator_pem == "" ? file("${path.module}/certs/sp_validator_crt.pem") : var.sp_validator_pem
  mutating_webhook_ca_bundle   = var.proxy_injector_pem == "" ? file("${path.module}/certs/proxy_injector_crt.pem") : var.proxy_injector_pem

  # namespaces
  linkerd_namespace = var.namespace_name

  # component names
  linkerd_component_controller_name     = "controller"
  linkerd_component_destination_name    = "destination"
  linkerd_component_grafana_name        = "grafana"
  linkerd_component_heartbeat_name      = "heartbeat"
  linkerd_component_identity_name       = "identity"
  linkerd_component_prometheus_name     = "prometheus"
  linkerd_component_proxy_injector_name = "proxy-injector"
  linkerd_component_sp_validator_name   = "sp-validator"
  linkerd_component_tap_name            = "tap"
  linkerd_component_web_name            = "web"

  # container names
  linkerd_init_container_name  = "linkerd-init"
  linkerd_proxy_container_name = "linkerd-proxy"
  linkerd_controller_name      = "linkerd-controller"
  linkerd_destination_name     = "linkerd-destination"
  linkerd_grafana_name         = "linkerd-grafana"
  linkerd_heartbeat_name       = "linkerd-heartbeat"
  linkerd_identity_name        = "linkerd-identity"
  linkerd_prometheus_name      = "linkerd-prometheus"
  linkerd_proxy_injector_name  = "linkerd-proxy-injector"
  linkerd_sp_validator_name    = "linkerd-sp-validator"
  linkerd_tap_name             = "linkerd-tap"
  linkerd_web_name             = "linkerd-web"

  # replicas
  controlplane_replicas = var.high_availability ? var.controlplane_ha_replicas : 1

  # annotations
  linkerd_annotation_created_by = {
    "linkerd.io/created-by" = format("linkerd/helm %s", var.controller_image_tag)
  }

  linkerd_annotations_for_deployment = {
    "linkerd.io/created-by"    = format("linkerd/helm %s", var.controller_image_tag),
    "linkerd.io/identity-mode" = "default",
    "linkerd.io/proxy-version" = var.controller_image_tag
  }

  # labels
  linkerd_label_control_plane_ns = {
    "linkerd.io/control-plane-ns" = local.linkerd_namespace
  }

  linkerd_label_workload_ns = {
    "linkerd.io/workload-ns" = local.linkerd_namespace
  }

  linkerd_label_partof_version = {
    "app.kubernetes.io/part-of" = "Linkerd",
    "app.kubernetes.io/version" = var.controller_image_tag
  }

  # deployment images
  linkerd_deployment_proxy_image      = format("%s:%s", var.proxy_image, var.proxy_image_tag)
  linkerd_deployment_proxy_init_image = format("%s:%s", var.proxy_init_image, var.proxy_init_image_tag)
  linkerd_deployment_controller_image = format("%s:%s", var.controller_image, var.controller_image_tag)

  # deployment security context
  linkerd_deployment_security_context_user = 2013

  # deployment ports
  linkerd_deployment_proxy_port_name = "linkerd-proxy"
  linkerd_deployment_admin_port_name = "linkerd-admin"

  linkerd_deployment_incoming_proxy_port = 4143
  linkerd_deployment_outgoing_proxy_port = 4140
  linkerd_deployment_proxy_uid           = 2102
  linkerd_deployment_proxy_control_port  = 4190
  linkerd_deployment_admin_port          = 4191
  linkerd_deployment_outbound_port       = 433

  # deployment env variables
  linkerd_trust_domain = var.trust_domain
  linkerd_deployment_container_env_variables = [
    {
      name  = "LINKERD2_PROXY_LOG"
      value = format("warn,linkerd=%s", var.container_log_level)
    },
    {
      name  = "LINKERD2_PROXY_DESTINATION_GET_NETWORKS"
      value = "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
    },
    {
      name  = "LINKERD2_PROXY_CONTROL_LISTEN_ADDR"
      value = "0.0.0.0:${local.linkerd_deployment_proxy_control_port}"
    },
    {
      name  = "LINKERD2_PROXY_ADMIN_LISTEN_ADDR"
      value = "0.0.0.0:${local.linkerd_deployment_admin_port}"
    },
    {
      name  = "LINKERD2_PROXY_OUTBOUND_LISTEN_ADDR"
      value = "127.0.0.1:${local.linkerd_deployment_outgoing_proxy_port}"
    },
    {
      name  = "LINKERD2_PROXY_INBOUND_LISTEN_ADDR"
      value = "0.0.0.0:${local.linkerd_deployment_incoming_proxy_port}"
    },
    {
      name  = "LINKERD2_PROXY_DESTINATION_GET_SUFFIXES"
      value = "svc.${local.linkerd_trust_domain}."
    },
    {
      name  = "LINKERD2_PROXY_DESTINATION_PROFILE_SUFFIXES"
      value = "svc.${local.linkerd_trust_domain}."
    },
    {
      name  = "LINKERD2_PROXY_INBOUND_ACCEPT_KEEPALIVE"
      value = "10000ms"
    },
    {
      name  = "LINKERD2_PROXY_OUTBOUND_CONNECT_KEEPALIVE"
      value = "10000ms"
    },
    {
      name  = "LINKERD2_PROXY_DESTINATION_CONTEXT"
      value = "ns:$(_pod_ns)"
    },
    {
      name  = "LINKERD2_PROXY_IDENTITY_DIR"
      value = "/var/run/linkerd/identity/end-entity"
    },
    {
      name  = "LINKERD2_PROXY_IDENTITY_TRUST_ANCHORS"
      value = local.trustAnchorsPEM
    },
    {
      name  = "LINKERD2_PROXY_IDENTITY_TOKEN_FILE"
      value = "/var/run/secrets/kubernetes.io/serviceaccount/token"
    },
    {
      name  = "_l5d_ns"
      value = local.linkerd_namespace
    },
    {
      name  = "_l5d_trustdomain"
      value = local.linkerd_trust_domain
    },
    {
      name  = "LINKERD2_PROXY_IDENTITY_LOCAL_NAME"
      value = "$(_pod_sa).$(_pod_ns).serviceaccount.identity.$(_l5d_ns).$(_l5d_trustdomain)"
    },
    {
      name  = "LINKERD2_PROXY_IDENTITY_SVC_NAME"
      value = "linkerd-identity.$(_l5d_ns).serviceaccount.identity.$(_l5d_ns).$(_l5d_trustdomain)"
    },
    {
      name  = "LINKERD2_PROXY_DESTINATION_SVC_NAME"
      value = "linkerd-destination.$(_l5d_ns).serviceaccount.identity.$(_l5d_ns).$(_l5d_trustdomain)"
    },
    {
      name  = "LINKERD2_PROXY_TAP_SVC_NAME"
      value = "linkerd-tap.$(_l5d_ns).serviceaccount.identity.$(_l5d_ns).$(_l5d_trustdomain)"
    }
  ]

  linkerd_proxy_destination_svc_addr = "linkerd-dst.${local.linkerd_namespace}.svc.${local.linkerd_trust_domain}:8086"
  linkerd_proxy_identity_svc_addr    = "linkerd-identity.${local.linkerd_namespace}.svc.${local.linkerd_trust_domain}:8080"

  #log level
  linkerd_container_log_level = var.container_log_level
}
