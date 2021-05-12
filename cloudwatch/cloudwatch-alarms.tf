resource "aws_cloudwatch_metric_alarm" "website" {
    for_each = var.cloudwatch_metric_alarms

    alarm_name          = each.key
    comparison_operator = each.value.comparison_operator
    evaluation_periods  = each.value.evaluation_periods
    metric_name         = each.value.metric_name
    namespace           = each.value.namespace
    period              = each.value.period
    statistic           = each.value.statistic
    threshold           = each.value.threshold
    dimensions          = each.value.dimensions
    alarm_description   = each.value.alarm_description
    alarm_actions       = each.value.alarm_actions

    tags = {
        Service     = var.service
        Environment = var.environment
        CostCentre  = var.cost_centre
        Owner       = var.owner
        CreatedBy   = var.created_by
        Terraform   = true
    }
}
