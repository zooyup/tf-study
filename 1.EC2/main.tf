# 기본 VPC id 가져오기
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default-pub-a" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name = "tag:Name"
    values = ["default-pub-a"]
  }
}

# 최신 amazon linux 2023 이미지 가져오기
data "aws_ami" "amazon-linux-2023" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["al2023-ami-2023*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name = "architecture"
    values = ["x86_64"]
  }
}

# 인스턴스 생성
resource "aws_instance" "tf-test" {
  ami = data.aws_ami.amazon-linux-2023.id
  instance_type = "t3.micro"
  subnet_id = data.aws_subnet.default-pub-a.id
  vpc_security_group_ids = [aws_security_group.tf-test-sg.id]
  key_name = "본인 키로 변경할 것"

  user_data = <<-EOF
    #!/bin/bash
    dnf -y update
    dnf -y install httpd
    echo "Hello, World!" > /var/www/html/index.html
    systemctl start httpd
    systemctl enable httpd
  EOF

  tags = {
    Name = "tf-test"
    Make = "terraform"
  }
}

resource "aws_security_group" "tf-test-sg" {
  name = "tf-test-sg"
  description = "tf-test-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-test-sg"
    Make = "terraform"
  }
}

output "public_ip" {
  value = aws_instance.tf-test.public_ip
}