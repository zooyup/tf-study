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

data "aws_subnet" "default-pub-c" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name = "tag:Name"
    values = ["default-pub-c"]
  }
}

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