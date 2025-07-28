locals {
  emr_flink_operator_name = "flink-kubernetes-operator"
  emr_release_label       = "emr-7.1.0-flink-k8s-operator-latest"

  emr_flink_operator_values = yamlencode(merge(
    yamldecode(<<EOT
    # Move ths Part to SET Section
emrContainers:
  awsRegion: ${local.region}
  emrReleaseLabel: ${local.emr_release_label}

EOT
    ),
    try(yamldecode(var.emr_flink_operator_helm_config.values[0]), {})
  ))
}

resource "helm_release" "emr_flink_operator" {
  count = var.enable_emr_flink_operator ? 1 : 0

  name                       = try(var.emr_flink_operator_helm_config["name"], local.emr_flink_operator_name)
  repository                 = try(var.emr_flink_operator_helm_config["repository"], "oci://public.ecr.aws/emr-on-eks")
  chart                      = try(var.emr_flink_operator_helm_config["chart"], local.emr_flink_operator_name)
  version                    = try(var.emr_flink_operator_helm_config["version"], "7.1.0")
  timeout                    = try(var.emr_flink_operator_helm_config["timeout"], 300)
  values                     = try(var.emr_flink_operator_helm_config["values"], [local.emr_flink_operator_values])
  create_namespace           = try(var.emr_flink_operator_helm_config["create_namespace"], true)
  namespace                  = try(var.emr_flink_operator_helm_config["namespace"], local.emr_flink_operator_name)
  lint                       = try(var.emr_flink_operator_helm_config["lint"], false)
  description                = try(var.emr_flink_operator_helm_config["description"], "")
  repository_key_file        = try(var.emr_flink_operator_helm_config["repository_key_file"], "")
  repository_cert_file       = try(var.emr_flink_operator_helm_config["repository_cert_file"], "")
  repository_username        = try(var.emr_flink_operator_helm_config["repository_username"], "")
  repository_password        = try(var.emr_flink_operator_helm_config["repository_password"], "")
  verify                     = try(var.emr_flink_operator_helm_config["verify"], false)
  keyring                    = try(var.emr_flink_operator_helm_config["keyring"], "")
  disable_webhooks           = try(var.emr_flink_operator_helm_config["disable_webhooks"], false)
  reuse_values               = try(var.emr_flink_operator_helm_config["reuse_values"], false)
  reset_values               = try(var.emr_flink_operator_helm_config["reset_values"], false)
  force_update               = try(var.emr_flink_operator_helm_config["force_update"], true)
  recreate_pods              = try(var.emr_flink_operator_helm_config["recreate_pods"], false)
  cleanup_on_fail            = try(var.emr_flink_operator_helm_config["cleanup_on_fail"], false)
  max_history                = try(var.emr_flink_operator_helm_config["max_history"], 0)
  atomic                     = try(var.emr_flink_operator_helm_config["atomic"], false)
  skip_crds                  = try(var.emr_flink_operator_helm_config["skip_crds"], false)
  render_subchart_notes      = try(var.emr_flink_operator_helm_config["render_subchart_notes"], true)
  disable_openapi_validation = try(var.emr_flink_operator_helm_config["disable_openapi_validation"], false)
  wait                       = try(var.emr_flink_operator_helm_config["wait"], true)
  wait_for_jobs              = try(var.emr_flink_operator_helm_config["wait_for_jobs"], false)
  dependency_update          = try(var.emr_flink_operator_helm_config["dependency_update"], false)
  replace                    = try(var.emr_flink_operator_helm_config["replace"], false)

  set {
    name  = "emrContainers.operatorExecutionRoleArn"
    value = try(var.emr_flink_operator_helm_config["operatorExecutionRoleArn"], null)
  }

  postrender {
    binary_path = try(var.emr_flink_operator_helm_config["postrender"], "")
  }

  dynamic "set" {
    iterator = each_item
    for_each = try(var.emr_flink_operator_helm_config["set"], [])

    content {
      name  = each_item.value.name
      value = each_item.value.value
      type  = try(each_item.value.type, null)
    }
  }

  dynamic "set_sensitive" {
    iterator = each_item
    for_each = try(var.emr_flink_operator_helm_config["set_sensitive"], [])

    content {
      name  = each_item.value.name
      value = each_item.value.value
      type  = try(each_item.value.type, null)
    }
  }

}
