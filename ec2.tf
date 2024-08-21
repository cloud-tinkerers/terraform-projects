data "aws_ami" "al2023_latest" {
  most_recent = true
  name_regex = "^al2023-ami-[0-9]{4}.[0-9].[0-9]{8}.[0-9]-kernel-[0-9]+.[0-9]+-x86_64"
  filter {
    name = "architecture"
    values = ["x86_64"]
  }
  owners = ["amazon"]
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023_latest.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [ aws_security_group.main.id ]
  key_name                    = aws_key_pair.ssh_key.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_role.name
  user_data = <<EOF
#!/bin/bash

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
project=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/tags/instance/Name)
sudo yum upgrade -y
sudo yum install -y httpd
echo "Welcome to $${project}" > /var/www/html/index.html
sudo systemctl start httpd
EOF
  metadata_options {
    http_endpoint               = "enabled"
    instance_metadata_tags      = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  tags = {
    Name = "${var.project}"
  }
}

resource "aws_key_pair" "ssh_key" {
  key_name = "main"
  public_key = "<your-PUBLIC-ssh-key"
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy" "ssm_managed_instance_core" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssm_role_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = data.aws_iam_policy.ssm_managed_instance_core.arn
}

resource "aws_iam_instance_profile" "ec2_role" {
  name = "ec2-role"
  role = aws_iam_role.ec2_role.name
}