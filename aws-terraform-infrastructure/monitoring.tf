# ==============================================================================
# Amazon CloudWatch Logs & Monitoring Alarms
# ==============================================================================

# Application CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${local.name_prefix}-app"
  retention_in_days = 7

  tags = local.common_tags
}

# Alarm: High EC2 CPU Utilization across Auto Scaling Group
resource "aws_cloudwatch_metric_alarm" "asg_high_cpu" {
  alarm_name          = "${local.name_prefix}-asg-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when ASG average CPU utilization exceeds 80% for 4 minutes"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = local.common_tags
}

# Alarm: ALB HTTP 5XX Errors
resource "aws_cloudwatch_metric_alarm" "alb_high_5xx" {
  alarm_name          = "${local.name_prefix}-alb-high-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Triggers if target instances generate more than 10 5XX HTTP responses in 1 minute"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = local.common_tags
}

# Alarm: Low RDS Free Storage Space
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "${local.name_prefix}-rds-low-free-storage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5368709120 # 5 GB in bytes
  alarm_description   = "Triggers when free storage on RDS instance drops below 5 GB"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  tags = local.common_tags
}
