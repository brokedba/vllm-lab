# EKS Managed Node Group Module

Configuration in this directory creates an EKS Managed Node Group along with an IAM role, security group, and launch template

## Usage

```hcl
module "eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"

  name            = "separate-eks-mng"
  cluster_name    = "my-cluster"
  cluster_version = "1.31"

  subnet_ids = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]

  // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
  // Without it, the security groups of the nodes are empty and thus won't join the cluster.
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks.node_security_group_id]

  // Note: `disk_size`, and `remote_access` can only be set when using the EKS managed node group default launch template
  // This module defaults to providing a custom launch template to allow for custom security groups, tag propagation, etc.
  // use_custom_launch_template = false
  // disk_size = 50
  //
  //  # Remote access cannot be specified with a launch template
  //  remote_access = {
  //    ec2_ssh_key               = module.key_pair.key_pair_name
  //    source_security_group_ids = [aws_security_group.remote_access.id]
  //  }

  min_size     = 1
  max_size     = 10
  desired_size = 1

  instance_types = ["t3.large"]
  capacity_type  = "SPOT"

  labels = {
    Environment = "test"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  taints = {
    dedicated = {
      key    = "dedicated"
      value  = "gpuGroup"
      effect = "NO_SCHEDULE"
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.95, < 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.95, < 6.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_user_data"></a> [user\_data](#module\_user\_data) | ../_user_data | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_schedule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_eks_node_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_placement_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/placement_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ec2_instance_type.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type) | data source |
| [aws_ec2_instance_type_offerings.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type_offerings) | data source |
| [aws_iam_policy_document.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_ssm_parameter.ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_subnets.placement_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | The AMI from which to launch the instance. If not supplied, EKS will use its own default image | `string` | `""` | no |
| <a name="input_ami_release_version"></a> [ami\_release\_version](#input\_ami\_release\_version) | The AMI version. Defaults to latest AMI release version for the given Kubernetes version and AMI type | `string` | `null` | no |
| <a name="input_ami_type"></a> [ami\_type](#input\_ami\_type) | Type of Amazon Machine Image (AMI) associated with the EKS Node Group. See the [AWS documentation](https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType) for valid values | `string` | `null` | no |
| <a name="input_block_device_mappings"></a> [block\_device\_mappings](#input\_block\_device\_mappings) | Specify volumes to attach to the instance besides the volumes specified by the AMI | `any` | `{}` | no |
| <a name="input_bootstrap_extra_args"></a> [bootstrap\_extra\_args](#input\_bootstrap\_extra\_args) | Additional arguments passed to the bootstrap script. When `ami_type` = `BOTTLEROCKET_*`; these are additional [settings](https://github.com/bottlerocket-os/bottlerocket#settings) that are provided to the Bottlerocket user data | `string` | `""` | no |
| <a name="input_capacity_reservation_specification"></a> [capacity\_reservation\_specification](#input\_capacity\_reservation\_specification) | Targeting for EC2 capacity reservations | `any` | `{}` | no |
| <a name="input_capacity_type"></a> [capacity\_type](#input\_capacity\_type) | Type of capacity associated with the EKS Node Group. Valid values: `ON_DEMAND`, `SPOT` | `string` | `"ON_DEMAND"` | no |
| <a name="input_cloudinit_post_nodeadm"></a> [cloudinit\_post\_nodeadm](#input\_cloudinit\_post\_nodeadm) | Array of cloud-init document parts that are created after the nodeadm document part | <pre>list(object({<br/>    content      = string<br/>    content_type = optional(string)<br/>    filename     = optional(string)<br/>    merge_type   = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_cloudinit_pre_nodeadm"></a> [cloudinit\_pre\_nodeadm](#input\_cloudinit\_pre\_nodeadm) | Array of cloud-init document parts that are created before the nodeadm document part | <pre>list(object({<br/>    content      = string<br/>    content_type = optional(string)<br/>    filename     = optional(string)<br/>    merge_type   = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_cluster_auth_base64"></a> [cluster\_auth\_base64](#input\_cluster\_auth\_base64) | Base64 encoded CA of associated EKS cluster | `string` | `""` | no |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | Endpoint of associated EKS cluster | `string` | `""` | no |
| <a name="input_cluster_ip_family"></a> [cluster\_ip\_family](#input\_cluster\_ip\_family) | The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6` | `string` | `"ipv4"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of associated EKS cluster | `string` | `null` | no |
| <a name="input_cluster_primary_security_group_id"></a> [cluster\_primary\_security\_group\_id](#input\_cluster\_primary\_security\_group\_id) | The ID of the EKS cluster primary security group to associate with the instance(s). This is the security group that is automatically created by the EKS service | `string` | `null` | no |
| <a name="input_cluster_service_cidr"></a> [cluster\_service\_cidr](#input\_cluster\_service\_cidr) | The CIDR block (IPv4 or IPv6) used by the cluster to assign Kubernetes service IP addresses. This is derived from the cluster itself | `string` | `""` | no |
| <a name="input_cluster_service_ipv4_cidr"></a> [cluster\_service\_ipv4\_cidr](#input\_cluster\_service\_ipv4\_cidr) | [Deprecated] The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks | `string` | `null` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version. Defaults to EKS Cluster Kubernetes version | `string` | `null` | no |
| <a name="input_cpu_options"></a> [cpu\_options](#input\_cpu\_options) | The CPU options for the instance | `map(string)` | `{}` | no |
| <a name="input_create"></a> [create](#input\_create) | Determines whether to create EKS managed node group or not | `bool` | `true` | no |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | Determines whether an IAM role is created or to use an existing IAM role | `bool` | `true` | no |
| <a name="input_create_iam_role_policy"></a> [create\_iam\_role\_policy](#input\_create\_iam\_role\_policy) | Determines whether an IAM role policy is created or not | `bool` | `true` | no |
| <a name="input_create_launch_template"></a> [create\_launch\_template](#input\_create\_launch\_template) | Determines whether to create a launch template or not. If set to `false`, EKS will use its own default launch template | `bool` | `true` | no |
| <a name="input_create_placement_group"></a> [create\_placement\_group](#input\_create\_placement\_group) | Determines whether a placement group is created & used by the node group | `bool` | `false` | no |
| <a name="input_create_schedule"></a> [create\_schedule](#input\_create\_schedule) | Determines whether to create autoscaling group schedule or not | `bool` | `true` | no |
| <a name="input_credit_specification"></a> [credit\_specification](#input\_credit\_specification) | Customize the credit specification of the instance | `map(string)` | `{}` | no |
| <a name="input_desired_size"></a> [desired\_size](#input\_desired\_size) | Desired number of instances/nodes | `number` | `1` | no |
| <a name="input_disable_api_termination"></a> [disable\_api\_termination](#input\_disable\_api\_termination) | If true, enables EC2 instance termination protection | `bool` | `null` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | Disk size in GiB for nodes. Defaults to `20`. Only valid when `use_custom_launch_template` = `false` | `number` | `null` | no |
| <a name="input_ebs_optimized"></a> [ebs\_optimized](#input\_ebs\_optimized) | If true, the launched EC2 instance(s) will be EBS-optimized | `bool` | `null` | no |
| <a name="input_efa_indices"></a> [efa\_indices](#input\_efa\_indices) | The indices of the network interfaces that should be EFA-enabled. Only valid when `enable_efa_support` = `true` | `list(number)` | <pre>[<br/>  0<br/>]</pre> | no |
| <a name="input_elastic_gpu_specifications"></a> [elastic\_gpu\_specifications](#input\_elastic\_gpu\_specifications) | The elastic GPU to attach to the instance | `any` | `{}` | no |
| <a name="input_elastic_inference_accelerator"></a> [elastic\_inference\_accelerator](#input\_elastic\_inference\_accelerator) | Configuration block containing an Elastic Inference Accelerator to attach to the instance | `map(string)` | `{}` | no |
| <a name="input_enable_bootstrap_user_data"></a> [enable\_bootstrap\_user\_data](#input\_enable\_bootstrap\_user\_data) | Determines whether the bootstrap configurations are populated within the user data template. Only valid when using a custom AMI via `ami_id` | `bool` | `false` | no |
| <a name="input_enable_efa_only"></a> [enable\_efa\_only](#input\_enable\_efa\_only) | Determines whether to enable EFA (`false`, default) or EFA and EFA-only (`true`) network interfaces. Note: requires vpc-cni version `v1.18.4` or later | `bool` | `false` | no |
| <a name="input_enable_efa_support"></a> [enable\_efa\_support](#input\_enable\_efa\_support) | Determines whether to enable Elastic Fabric Adapter (EFA) support | `bool` | `false` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Enables/disables detailed monitoring | `bool` | `true` | no |
| <a name="input_enclave_options"></a> [enclave\_options](#input\_enclave\_options) | Enable Nitro Enclaves on launched instances | `map(string)` | `{}` | no |
| <a name="input_force_update_version"></a> [force\_update\_version](#input\_force\_update\_version) | Force version update if existing pods are unable to be drained due to a pod disruption budget issue | `bool` | `null` | no |
| <a name="input_iam_role_additional_policies"></a> [iam\_role\_additional\_policies](#input\_iam\_role\_additional\_policies) | Additional policies to be added to the IAM role | `map(string)` | `{}` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | Existing IAM role ARN for the node group. Required if `create_iam_role` is set to `false` | `string` | `null` | no |
| <a name="input_iam_role_attach_cni_policy"></a> [iam\_role\_attach\_cni\_policy](#input\_iam\_role\_attach\_cni\_policy) | Whether to attach the `AmazonEKS_CNI_Policy`/`AmazonEKS_CNI_IPv6_Policy` IAM policy to the IAM IAM role. WARNING: If set `false` the permissions must be assigned to the `aws-node` DaemonSet pods via another method or nodes will not be able to join the cluster | `bool` | `true` | no |
| <a name="input_iam_role_description"></a> [iam\_role\_description](#input\_iam\_role\_description) | Description of the role | `string` | `null` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Name to use on IAM role created | `string` | `null` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | IAM role path | `string` | `null` | no |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| <a name="input_iam_role_policy_statements"></a> [iam\_role\_policy\_statements](#input\_iam\_role\_policy\_statements) | A list of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) - used for adding specific IAM permissions as needed | `any` | `[]` | no |
| <a name="input_iam_role_tags"></a> [iam\_role\_tags](#input\_iam\_role\_tags) | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| <a name="input_iam_role_use_name_prefix"></a> [iam\_role\_use\_name\_prefix](#input\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name (`iam_role_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_instance_market_options"></a> [instance\_market\_options](#input\_instance\_market\_options) | The market (purchasing) option for the instance | `any` | `{}` | no |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | Set of instance types associated with the EKS Node Group. Defaults to `["t3.medium"]` | `list(string)` | `null` | no |
| <a name="input_kernel_id"></a> [kernel\_id](#input\_kernel\_id) | The kernel ID | `string` | `null` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | The key name that should be used for the instance(s) | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Key-value map of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed | `map(string)` | `null` | no |
| <a name="input_launch_template_default_version"></a> [launch\_template\_default\_version](#input\_launch\_template\_default\_version) | Default version of the launch template | `string` | `null` | no |
| <a name="input_launch_template_description"></a> [launch\_template\_description](#input\_launch\_template\_description) | Description of the launch template | `string` | `null` | no |
| <a name="input_launch_template_id"></a> [launch\_template\_id](#input\_launch\_template\_id) | The ID of an existing launch template to use. Required when `create_launch_template` = `false` and `use_custom_launch_template` = `true` | `string` | `""` | no |
| <a name="input_launch_template_name"></a> [launch\_template\_name](#input\_launch\_template\_name) | Name of launch template to be created | `string` | `null` | no |
| <a name="input_launch_template_tags"></a> [launch\_template\_tags](#input\_launch\_template\_tags) | A map of additional tags to add to the tag\_specifications of launch template created | `map(string)` | `{}` | no |
| <a name="input_launch_template_use_name_prefix"></a> [launch\_template\_use\_name\_prefix](#input\_launch\_template\_use\_name\_prefix) | Determines whether to use `launch_template_name` as is or create a unique name beginning with the `launch_template_name` as the prefix | `bool` | `true` | no |
| <a name="input_launch_template_version"></a> [launch\_template\_version](#input\_launch\_template\_version) | Launch template version number. The default is `$Default` | `string` | `null` | no |
| <a name="input_license_specifications"></a> [license\_specifications](#input\_license\_specifications) | A map of license specifications to associate with | `any` | `{}` | no |
| <a name="input_maintenance_options"></a> [maintenance\_options](#input\_maintenance\_options) | The maintenance options for the instance | `any` | `{}` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of instances/nodes | `number` | `3` | no |
| <a name="input_metadata_options"></a> [metadata\_options](#input\_metadata\_options) | Customize the metadata options for the instance | `map(string)` | <pre>{<br/>  "http_endpoint": "enabled",<br/>  "http_put_response_hop_limit": 2,<br/>  "http_tokens": "required"<br/>}</pre> | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of instances/nodes | `number` | `0` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the EKS managed node group | `string` | `""` | no |
| <a name="input_network_interfaces"></a> [network\_interfaces](#input\_network\_interfaces) | Customize network interfaces to be attached at instance boot time | `list(any)` | `[]` | no |
| <a name="input_node_repair_config"></a> [node\_repair\_config](#input\_node\_repair\_config) | The node auto repair configuration for the node group | <pre>object({<br/>    enabled = optional(bool, true)<br/>  })</pre> | `null` | no |
| <a name="input_placement"></a> [placement](#input\_placement) | The placement of the instance | `map(string)` | `{}` | no |
| <a name="input_placement_group_az"></a> [placement\_group\_az](#input\_placement\_group\_az) | Availability zone where placement group is created (ex. `eu-west-1c`) | `string` | `null` | no |
| <a name="input_placement_group_strategy"></a> [placement\_group\_strategy](#input\_placement\_group\_strategy) | The placement group strategy | `string` | `"cluster"` | no |
| <a name="input_platform"></a> [platform](#input\_platform) | [DEPRECATED - use `ami_type` instead. Will be removed in `v21.0`] Identifies the OS platform as `bottlerocket`, `linux` (AL2), `al2023`, or `windows` | `string` | `"linux"` | no |
| <a name="input_post_bootstrap_user_data"></a> [post\_bootstrap\_user\_data](#input\_post\_bootstrap\_user\_data) | User data that is appended to the user data script after of the EKS bootstrap script. Not used when `ami_type` = `BOTTLEROCKET_*` | `string` | `""` | no |
| <a name="input_pre_bootstrap_user_data"></a> [pre\_bootstrap\_user\_data](#input\_pre\_bootstrap\_user\_data) | User data that is injected into the user data script ahead of the EKS bootstrap script. Not used when `ami_type` = `BOTTLEROCKET_*` | `string` | `""` | no |
| <a name="input_private_dns_name_options"></a> [private\_dns\_name\_options](#input\_private\_dns\_name\_options) | The options for the instance hostname. The default values are inherited from the subnet | `map(string)` | `{}` | no |
| <a name="input_ram_disk_id"></a> [ram\_disk\_id](#input\_ram\_disk\_id) | The ID of the ram disk | `string` | `null` | no |
| <a name="input_remote_access"></a> [remote\_access](#input\_remote\_access) | Configuration block with remote access settings. Only valid when `use_custom_launch_template` = `false` | `any` | `{}` | no |
| <a name="input_schedules"></a> [schedules](#input\_schedules) | Map of autoscaling group schedule to create | `map(any)` | `{}` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Identifiers of EC2 Subnets to associate with the EKS Node Group. These subnets must have the following resource tag: `kubernetes.io/cluster/CLUSTER_NAME` | `list(string)` | `null` | no |
| <a name="input_tag_specifications"></a> [tag\_specifications](#input\_tag\_specifications) | The tags to apply to the resources during launch | `list(string)` | <pre>[<br/>  "instance",<br/>  "volume",<br/>  "network-interface"<br/>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_taints"></a> [taints](#input\_taints) | The Kubernetes taints to be applied to the nodes in the node group. Maximum of 50 taints per node group | `any` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Create, update, and delete timeout configurations for the node group | `map(string)` | `{}` | no |
| <a name="input_update_config"></a> [update\_config](#input\_update\_config) | Configuration block of settings for max unavailable resources during node group updates | `map(string)` | <pre>{<br/>  "max_unavailable_percentage": 33<br/>}</pre> | no |
| <a name="input_update_launch_template_default_version"></a> [update\_launch\_template\_default\_version](#input\_update\_launch\_template\_default\_version) | Whether to update the launch templates default version on each update. Conflicts with `launch_template_default_version` | `bool` | `true` | no |
| <a name="input_use_custom_launch_template"></a> [use\_custom\_launch\_template](#input\_use\_custom\_launch\_template) | Determines whether to use a custom launch template or not. If set to `false`, EKS will use its own default launch template | `bool` | `true` | no |
| <a name="input_use_latest_ami_release_version"></a> [use\_latest\_ami\_release\_version](#input\_use\_latest\_ami\_release\_version) | Determines whether to use the latest AMI release version for the given `ami_type` (except for `CUSTOM`). Note: `ami_type` and `cluster_version` must be supplied in order to enable this feature | `bool` | `false` | no |
| <a name="input_use_name_prefix"></a> [use\_name\_prefix](#input\_use\_name\_prefix) | Determines whether to use `name` as is or create a unique name beginning with the `name` as the prefix | `bool` | `true` | no |
| <a name="input_user_data_template_path"></a> [user\_data\_template\_path](#input\_user\_data\_template\_path) | Path to a local, custom user data template file to use when rendering user data | `string` | `""` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | A list of security group IDs to associate | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_schedule_arns"></a> [autoscaling\_group\_schedule\_arns](#output\_autoscaling\_group\_schedule\_arns) | ARNs of autoscaling group schedules |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | The Amazon Resource Name (ARN) specifying the IAM role |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | The name of the IAM role |
| <a name="output_iam_role_unique_id"></a> [iam\_role\_unique\_id](#output\_iam\_role\_unique\_id) | Stable and unique string identifying the IAM role |
| <a name="output_launch_template_arn"></a> [launch\_template\_arn](#output\_launch\_template\_arn) | The ARN of the launch template |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | The ID of the launch template |
| <a name="output_launch_template_latest_version"></a> [launch\_template\_latest\_version](#output\_launch\_template\_latest\_version) | The latest version of the launch template |
| <a name="output_launch_template_name"></a> [launch\_template\_name](#output\_launch\_template\_name) | The name of the launch template |
| <a name="output_node_group_arn"></a> [node\_group\_arn](#output\_node\_group\_arn) | Amazon Resource Name (ARN) of the EKS Node Group |
| <a name="output_node_group_autoscaling_group_names"></a> [node\_group\_autoscaling\_group\_names](#output\_node\_group\_autoscaling\_group\_names) | List of the autoscaling group names |
| <a name="output_node_group_id"></a> [node\_group\_id](#output\_node\_group\_id) | EKS Cluster name and EKS Node Group name separated by a colon (`:`) |
| <a name="output_node_group_labels"></a> [node\_group\_labels](#output\_node\_group\_labels) | Map of labels applied to the node group |
| <a name="output_node_group_resources"></a> [node\_group\_resources](#output\_node\_group\_resources) | List of objects containing information about underlying resources |
| <a name="output_node_group_status"></a> [node\_group\_status](#output\_node\_group\_status) | Status of the EKS Node Group |
| <a name="output_node_group_taints"></a> [node\_group\_taints](#output\_node\_group\_taints) | List of objects containing information about taints applied to the node group |
| <a name="output_platform"></a> [platform](#output\_platform) | [DEPRECATED - Will be removed in `v21.0`] Identifies the OS platform as `bottlerocket`, `linux` (AL2), `al2023`, or `windows` |
<!-- END_TF_DOCS -->
