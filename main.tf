terraform {
	required_version = ">= 1.2.0"

	backend "local" {
		path = "./secrets/terraform.tfstate"
	}

	required_providers {
		aws = {
			source	= "hashicorp/aws"
			version = "~> 4.16"
		}
	}
}

locals {
	ssh = {
		private_key = "./secrets/ssh/id_ed25519"
		public_key  = "./secrets/ssh/id_ed25519.pub"
	}
}

variable "tailnet_name" {
	description = "The name of the Tailscale tailnet"
	type = string
}

provider "aws" {
	profile = "acm"
	region = "us-west-2"
	shared_credentials_files = [ "./secrets/aws/credentials" ]
}

resource "aws_key_pair" "secrets_ssh" {
	key_name = "acm-secrets-ssh"
	public_key = file(local.ssh.public_key)
}

module "cirno" {
	host = "cirno.${var.tailnet_name}.ts.net"
	source = "./servers/cirno"
	key_name = aws_key_pair.secrets_ssh.key_name
	ssh_private_key_file = local.ssh.private_key
}

module "cs306" {
	host = "cs306.${var.tailnet_name}.ts.net"
	source = "./servers/cs306"
	ssh_private_key_file = local.ssh.private_key
}

module "cs306-mini" {
	host = "cs306-mini.${var.tailnet_name}.ts.net"
	source = "./servers/cs306-mini"
	ssh_private_key_file = local.ssh.private_key
}
