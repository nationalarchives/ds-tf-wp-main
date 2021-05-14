resource "aws_cloudwatch_metric_alarm" "website" {
    alarm_name          = var.cloudwatch_alarm_name
    comparison_operator = var.cloudwatch_alarm_comparison_operator
    evaluation_periods  = var.cloudwatch_alarm_evaluation_periods
    metric_name         = var.cloudwatch_alarm_metric_name
    namespace           = var.cloudwatch_alarm_namespace
    period              = var.cloudwatch_alarm_period
    statistic           = var.cloudwatch_alarm_statistic
    threshold           = var.cloudwatch_alarm_threshold
    dimensions          = var.cloudwatch_alarm_dimensions
    alarm_description   = var.cloudwatch_alarm_alarm_description
    alarm_actions       = var.cloudwatch_alarm_alarm_actions

    tags = {
        Service     = var.service
        Environment = var.environment
        CostCentre  = var.cost_centre
        Owner       = var.owner
        CreatedBy   = var.created_by
        Terraform   = true
    }
}
