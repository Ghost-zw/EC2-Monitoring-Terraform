terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket45"
    key            = "ec2-monitoring/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile = "terraform-locks"
  }
}