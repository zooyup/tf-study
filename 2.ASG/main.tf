# 시작 템플릿
resource "aws_launch_template" "tf-launch-template" {
    name = "${var.project_name}-lt"
    image_id = data.aws_ami.amazon-linux-2023.id
    instance_type = "t3.micro"
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.tf-web-sg.id]
    user_data = base64encode(<<-EOF
    #!/bin/bash
    TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
    INSTANCE_ID=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id`
    dnf -y update
    dnf -y install httpd
    echo "Hello, World! $INSTANCE_ID" > /var/www/html/index.html
    systemctl start httpd
    systemctl enable httpd
    EOF
    )

    tags = {
        Name = "${var.project_name}-lt"
        Make = "terraform"
    }
}

# Autoscaling Group
resource "aws_autoscaling_group" "tf-asg" {
    name = "${var.project_name}-asg"
    vpc_zone_identifier = [data.aws_subnet.default-pub-a.id, data.aws_subnet.default-pub-c.id]
    launch_template {
        id = aws_launch_template.tf-launch-template.id
        version = "$Latest"
    }
    min_size = 2
    max_size = 2
    desired_capacity = 2
    health_check_grace_period = 60
    target_group_arns = [aws_lb_target_group.tf-alb-tg.arn]
    tag {
        key = "Name"
        value = "${var.project_name}-asg"
        propagate_at_launch = true
    }
    tag {
        key = "Make"
        value = "terraform"
        propagate_at_launch = true
    }
}
# ALB 
resource "aws_lb" "tf-alb" {  
    name = "${var.project_name}-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.tf-alb-sg.id]
    subnets = [data.aws_subnet.default-pub-a.id, data.aws_subnet.default-pub-c.id]
}

resource "aws_lb_target_group" "tf-alb-tg" {
    name = "${var.project_name}-alb-80-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id
    health_check {
        path = "/"
        port = "traffic-port"
        protocol = "HTTP"
        matcher = "200"
        interval = 10
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
    deregistration_delay = 60

    tags = {
        Name = "${var.project_name}-alb-80-tg"
        Make = "terraform"
    }
}

resource "aws_lb_listener" "tf-alb-listener" {
    load_balancer_arn = aws_lb.tf-alb.arn
    port = 80
    protocol = "HTTP"
    tags = {
        Name = "${var.project_name}-alb-listener"
        Make = "terraform"
    }
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.tf-alb-tg.arn
    }
}
# 보안 그룹
resource "aws_security_group" "tf-web-sg" {
  name = "${var.project_name}-web-sg"
  description = "tf-test-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.tf-alb-sg.id]
  }

  egress {
    from_port = 0
    to_port = 0 
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
    Make = "terraform"
  }
}

resource "aws_security_group" "tf-alb-sg" {
  name = "${var.project_name}-alb-sg"
  description = "tf-alb-sg"
  vpc_id = data.aws_vpc.default.id


  ingress {
    from_port = 80
    to_port = 80
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
    Name = "${var.project_name}-alb-sg"
    Make = "terraform"
  }
}

output "alb_dns" {
  value = aws_lb.tf-alb.dns_name
}