provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}


data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  name   = basename(path.cwd)
  region = "${var.region}"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)


  tags = {
    ProvisionedBy  = "Terraform"
  }
}



################################################################################
# Cluster
################################################################################


module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 19.16"

  cluster_name    = "${var.cluster_name}"
  cluster_version = "1.27"
  cluster_endpoint_public_access = true

  cluster_enabled_log_types = [ "audit", "api", "authenticator", "controllerManager", "scheduler" ]


  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

################################################################################
# EKS Managed Addons
################################################################################
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-efs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.efs_csi_irsa_role.iam_role_arn
    }    
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }  
  } 


  eks_managed_node_group_defaults = {
    root_volume_type = "gp3"

    iam_role_additional_policies = {
      # Not required, but used in the example to access the nodes 
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      # Not required, but used in the example for nodes to access route53
      #AllowExternalDNSUpdates = "arn:aws:iam::aws:policy/AmazonRoute53AutoNamingFullAccess"
    }
    # enable discovery of autoscaling groups by cluster-autoscaler
    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${var.cluster_name}" : "owned",
    }

  }

#  Managed Node Group(s)
  eks_managed_node_groups = {
    worker-group-1 = {
      instance_types                = ["t3.medium", "t3.large"]
      # start with one worker node and let cluster autoscaler scale as needed
      desired_size                  = 1
      min_size                      = 1
      max_size                      = 7       
      subnet_ids                    = module.vpc.private_subnets
      capacity_type  = "SPOT"

      # Only valid when use_custom_launch_template = false
      disk_size = 100      
      use_custom_launch_template = false

    
    },
  }

  # Fargate Profile(s)
  fargate_profiles = {
    default = {
      name = "serverless"
      selectors = [
        {
          namespace = "serverless"
        }
      ]
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Admin"
      username = "Admin"
      groups   = ["system:masters"]
    },
  ]  

  tags = {
    Environment = "dev"
    ProvisionedBy   = "Terraform"
    auto-delete = "no"
  }

}


################################################################################
# EKS Blueprints Addons
################################################################################

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.7.1"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Add-ons
  enable_metrics_server     = true
  enable_cluster_autoscaler = true 
  enable_cert_manager       = true
  enable_aws_load_balancer_controller  = true
  enable_aws_cloudwatch_metrics = true

  enable_external_dns = true
  external_dns = {
    name          = "external-dns"
    chart_version = "1.12.2"
    repository    = "https://kubernetes-sigs.github.io/external-dns/"
    namespace     = "kube-system"
    #values        = [templatefile("${path.module}/values.yaml", {})]
  }
  external_dns_route53_zone_arns = ["*"]

  enable_aws_for_fluentbit = true
  aws_for_fluentbit_cw_log_group = {
    create          = true
    use_name_prefix = false # Set this to true to enable name prefix
    name_prefix     = "eks-cluster-logs-"
    retention       = 7
  }
  aws_for_fluentbit = {
    name          = "aws-for-fluent-bit"
    chart_version = "0.1.24"
    repository    = "https://aws.github.io/eks-charts"
    namespace     = "kube-system"
    #values        = [templatefile("${path.module}/values.yaml", {})]
    #in case of cross account, you can specify another region here
    set = [
      {
        name  = "cloudWatchLogs.region"
        value = local.region
      }
    ]    
  }

  depends_on = [
    module.eks
  ]

  tags = local.tags
}


################################################################################
# IRSA Roles
################################################################################



module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name_prefix = "${module.eks.cluster_name}-ebs-csi-driver-"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

module "efs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name_prefix = "${module.eks.cluster_name}-efs-csi-"
  attach_efs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

module "external_dns_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name_prefix = "${module.eks.cluster_name}-external-dns-"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/*"]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

  tags = local.tags
}

#---------------------------------------------------------------
# Sample App for Testing
#---------------------------------------------------------------

# For some reason the example pods can't be deployed right after helm install of cilium a delay needs to be introduced. This is being investigated
resource "time_sleep" "wait_delay" {
  count           = var.enable_example ? 1 : 0
  create_duration = "15s"

  depends_on = [
    module.eks
  ]
}

# Load all manifest documents via for_each (recommended)

data "kubectl_path_documents" "docs" {
    pattern = "./manifests/*.yml"
}

resource "kubectl_manifest" "test" {
    for_each  = toset(data.kubectl_path_documents.docs.documents)
    yaml_body = each.value

  depends_on = [time_sleep.wait_delay]    
}


################################################################################
# Dependent Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway     = true
  single_nat_gateway     = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}