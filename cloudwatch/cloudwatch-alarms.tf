resource "aws_cloudwatch_metric_alarm" "website_cpu" {
  alarm_name          = var.cloudwatch_metric_alarm_name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.cloudwatch_metric_alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cloudwatch_metric_alarm_period
  statistic           = var.cloudwatch_metric_alarm_statistic
  threshold           = var.cloudwatch_metric_alarm_threshold

  dimensions = {
    AutoScalingGroupName = var.website_autoscaling_group_name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [var.website_autoscaling_policy_arn]
}
