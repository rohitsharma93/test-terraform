# ==============================================================================
# EC2 Auto Scaling & Launch Template
# ==============================================================================

# Fetch latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template for Application EC2 Instances
resource "aws_launch_template" "main" {
  name_prefix   = "${local.name_prefix}-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.ec2_instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_profile.arn
  }

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd

              INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
              AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

              cat <<HTML > /var/www/html/index.html
              <!DOCTYPE html>
              <html>
              <head>
                <title>Demo Infrastructure</title>
                <style>
                  body { font-family: Arial, sans-serif; margin: 40px; background: #f7fafc; color: #2d3748; }
                  .card { background: white; border-radius: 8px; padding: 24px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); max-width: 600px; margin: 0 auto; }
                  h1 { color: #3182ce; }
                  .badge { display: inline-block; padding: 4px 8px; border-radius: 4px; background: #ebf8ff; color: #2b6cb0; font-weight: bold; }
                </style>
              </head>
              <body>
                <div class="card">
                  <h1>🚀 Terraform AWS Demo Infrastructure</h1>
                  <p>Application successfully running on AWS Auto Scaling Group behind ALB.</p>
                  <p><strong>Environment:</strong> <span class="badge">${var.environment}</span></p>
                  <p><strong>Instance ID:</strong> <code>$INSTANCE_ID</code></p>
                  <p><strong>Availability Zone:</strong> <code>$AZ</code></p>
                  <p><strong>Database Target:</strong> <code>${var.db_name}</code></p>
                </div>
              </body>
              </html>
              HTML
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-app-instance"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-app-volume"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name_prefix         = "${local.name_prefix}-asg-"
  vpc_zone_identifier = aws_subnet.private_app[*].id
  target_group_arns   = [aws_lb_target_group.main.arn]

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = merge(local.common_tags, {
      Name = "${local.name_prefix}-asg-instance"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}
