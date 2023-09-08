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

  # IPv6
  cluster_ip_family = "ipv6"
  create_cni_ipv6_iam_policy = "true"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

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
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Add-ons
  enable_metrics_server     = true
  enable_cluster_autoscaler = true 
  enable_cert_manager       = true
  enable_aws_load_balancer_controller  = true
  #enable_aws_fsx_csi_driver    = true

  tags = local.tags
}


################################################################################
# IRSA Roles
################################################################################


module "cert_manager_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name_prefix = "${module.eks.cluster_name}-cert-manager-"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = ["arn:aws:route53:::hostedzone/*"]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cert-manager"]
    }
  }

  tags = local.tags
}

module "cluster_autoscaler_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name_prefix = "${module.eks.cluster_name}-cluster-autoscaler-"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
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

module "load_balancer_controller_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name_prefix = "${module.eks.cluster_name}-load-balancer-controller-"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
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

resource "kubectl_manifest" "backendapp" {
  count = var.enable_example ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Pod"
    metadata = {
      name = "backendapp"
      labels = {
        name = "backendapp"
      }
    }
    spec = {
      containers = [
        {
          name  = "backendapp"
          image = "nginx"
        }
      ]
    }
  })

  depends_on = [time_sleep.wait_delay]
}

resource "kubectl_manifest" "service" {
  count = var.enable_example ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name = "backendapp"
      annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-type" = "external"
        "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
        "service.beta.kubernetes.io/aws-load-balancer-attributes" = "load_balancing.cross_zone.enabled=true"
        "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"   
      }
    }
    spec = {
      selector = {
        name = "backendapp"
      }
      ports = [
        {
          port = 80
        }
      ]
      type = "LoadBalancer"
    }
  })
  depends_on = [time_sleep.wait_delay]  
}

################################################################################
# Supporting Resources
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
  enable_ipv6            = true
  create_egress_only_igw = true

  public_subnet_ipv6_prefixes                    = [0, 1, 2]
  public_subnet_assign_ipv6_address_on_creation  = true
  private_subnet_ipv6_prefixes                   = [3, 4, 5]
  private_subnet_assign_ipv6_address_on_creation = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}