terraform {
  required_version = ">= 1.8.0"  # Latest stable Terraform version
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"  # Latest stable AWS provider
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
  
  backend "s3" {
    # Configure S3 backend for state management
    # bucket = "medinovai-terraform-state"
    # key    = "infrastructure/terraform.tfstate"
    # region = "us-east-1"
    # encrypt = true
    # dynamodb_table = "medinovai-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "MedinovAI"
      ManagedBy   = "Terraform"
      CostCenter  = "Infrastructure"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module for better networking security
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.17"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support = true

  # VPC Flow Logs for security monitoring
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# EKS Module with latest best practices
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"  # Latest stable EKS module

  cluster_name    = var.cluster_name
  cluster_version = "1.31"  # Latest stable EKS version

  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  control_plane_subnet_ids        = module.vpc.private_subnets
  
  # Enhanced security settings
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access_cidrs = var.allowed_cidr_blocks

  # Security and monitoring
  enable_cluster_creator_admin_permissions = true
  authentication_mode = "API_AND_CONFIG_MAP"
  
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
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
  }

  # EKS Managed Node Groups with latest instance types
  eks_managed_node_groups = {
    # General workloads - Graviton3 for better price/performance
    general = {
      instance_types = ["c7g.large", "c7g.xlarge"]
      capacity_type  = "ON_DEMAND"
      
      min_size     = 2
      max_size     = 10
      desired_size = 3

      # Latest AMI and improved security
      ami_type = "AL2023_ARM_64_STANDARD"  # Latest Amazon Linux 2023
      
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100
            volume_type           = "gp3"
            iops                 = 3000
            throughput           = 125
            encrypted            = true
            delete_on_termination = true
          }
        }
      }

      # Security configurations
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "enabled"
      }

      labels = {
        workload-type = "general"
      }

      taints = {}
    }

    # Spot instances for cost optimization
    spot = {
      instance_types = ["c7g.large", "c7g.xlarge", "m7g.large"]
      capacity_type  = "SPOT"
      
      min_size     = 0
      max_size     = 10
      desired_size = 2

      ami_type = "AL2023_ARM_64_STANDARD"
      
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100
            volume_type           = "gp3"
            iops                 = 3000
            throughput           = 125
            encrypted            = true
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "enabled"
      }

      labels = {
        workload-type = "spot"
      }

      taints = {
        spot = {
          key    = "spot"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }

    # Infrastructure workloads with dedicated nodes
    infrastructure = {
      instance_types = ["c7g.large"]
      capacity_type  = "ON_DEMAND"
      
      min_size     = 1
      max_size     = 3
      desired_size = 1

      ami_type = "AL2023_ARM_64_STANDARD"
      
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 150
            volume_type           = "gp3"
            iops                 = 3000
            throughput           = 125
            encrypted            = true
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "enabled"
      }

      labels = {
        workload-type = "infrastructure"
      }

      taints = {
        infrastructure = {
          key    = "infrastructure"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  # Cluster security group
  cluster_security_group_additional_rules = {
    ingress_nodes_443 = {
      description                = "Node groups to cluster API"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  # Node security group
  node_security_group_additional_rules = {
    ingress_cluster_443 = {
      description                   = "Cluster API to node groups"
      protocol                      = "tcp"
      from_port                     = 443
      to_port                       = 443
      type                         = "ingress"
      source_cluster_security_group = true
    }
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 65535
      type        = "ingress"
      self        = true
    }
  }

  tags = {
    Environment = var.environment
  }
}

# IAM role for EBS CSI driver
module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.52"

  role_name             = "${var.cluster_name}-ebs-csi-driver"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = {
    Environment = var.environment
  }
} 