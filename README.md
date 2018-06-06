#  AWS VPC Terraform module
------------

Modulo Terraform para criação de uma AWS VPC completa com subnets privadas e publicas, assim como as rotas padrões para acesso a internet por ambas as subnets através de IGW e NAT.

## Como usar
-------------

    module "vpc" {
      source        = "modules/terraform.aws.vpc"

      vpc_name      = "enterprise-dev"
      base_cidr_vpc = "10.0.0.0/16"

      tags = {
        Terraform   = "true"
        Environment = "dev"
      }
    }
