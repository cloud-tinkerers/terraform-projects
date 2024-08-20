data "aws_ami" "al2023_latest" {
  most_recent = true
  name_regex = "^al2023-ami-[0-9]{4}.[0-9].[0-9]{8}.[0-9]-kernel-[0-9]+.[0-9]+-arm64$"
  filter {
    name = "architecture"
    values = ["arm64"]
  }
  owners = ["amazon"]
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023_latest.id
  instance_type               = "t4g.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [ aws_security_group.main.id ]
  user_data = <<EOF
#!/bin/bash

sudo yum upgrade -y
sudo yum install -y httpd
echo "Hello world!" > /var/www/html/index.html
sudo systemctl start httpd
EOF

  tags = {
    Name = "main"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}