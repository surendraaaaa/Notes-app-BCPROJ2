
# INTERNAL ALBs

# SonarQube
resource "aws_lb" "sonar_alb" {
  name               = "sonar-internal-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = aws_subnet.private[*].id
  security_groups    = [aws_security_group.internal_sg.id]
}

resource "aws_lb_target_group" "sonar_tg" {
  name     = "sonar-tg"
  port     = var.sonar_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "sonar_listener" {
  load_balancer_arn = aws_lb.sonar_alb.arn
  port              = var.sonar_port
  protocol          = "HTTP"
  default_action { type = "forward"; target_group_arn = aws_lb_target_group.sonar_tg.arn }
}

resource "aws_lb_target_group_attachment" "sonar_attach" {
  target_group_arn = aws_lb_target_group.sonar_tg.arn
  target_id        = aws_instance.sonarqube.id
  port             = var.sonar_port
}

# Nexus
resource "aws_lb" "nexus_alb" {
  name               = "nexus-internal-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = aws_subnet.private[*].id
  security_groups    = [aws_security_group.internal_sg.id]
}

resource "aws_lb_target_group" "nexus_tg" {
  name     = "nexus-tg"
  port     = var.nexus_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "nexus_listener" {
  load_balancer_arn = aws_lb.nexus_alb.arn
  port              = var.nexus_port
  protocol          = "HTTP"
  default_action { type = "forward"; target_group_arn = aws_lb_target_group.nexus_tg.arn }
}

resource "aws_lb_target_group_attachment" "nexus_attach" {
  target_group_arn = aws_lb_target_group.nexus_tg.arn
  target_id        = aws_instance.nexus.id
  port             = var.nexus_port
}


