# Creating ALB for Web Tier
resource "aws_lb" "web-elb" {
  name                       = var.alb-name
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = [data.aws_subnet.public-subnet1.id, data.aws_subnet.public-subnet2.id]
  security_groups            = [data.aws_security_group.web-alb-sg.id]
  ip_address_type            = "ipv4"
  enable_deletion_protection = false
  tags = {
    Name = var.alb-name
  }
}

# Creating Target Group for Web-Tier 
resource "aws_lb_target_group" "web-tg" {
  name = var.tg-name
  health_check {
    enabled             = true
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
  target_type = "instance"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    Name = var.tg-name
  }

  lifecycle {
    prevent_destroy = false
  }
  depends_on = [aws_lb.web-elb]
}

resource "aws_lb_target_group_attachment" "web-tg-attachment-1" {
  target_group_arn = aws_lb_target_group.web-tg.arn
  target_id        = var.instance_id # Replace with your EC2 module output
  port             = 8080
}


# Creating ALB listener with port 80 and attaching it to Web-Tier Target Group
resource "aws_lb_listener" "web-alb-listener" {
  load_balancer_arn = aws_lb.web-elb.arn
  port              = 80
  protocol          = "HTTP"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-tg.arn
  }

  depends_on = [aws_lb.web-elb, aws_lb_target_group.web-tg]
}

resource "aws_lb_listener" "web-alb-https-listener" {
  load_balancer_arn = aws_lb.web-elb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-south-1:636185081346:certificate/e2ca42d7-8287-4ec4-be17-6117eb42a00f" # ACM certificate ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-tg.arn
  }

  depends_on = [aws_lb.web-elb, aws_lb_target_group.web-tg]
}
