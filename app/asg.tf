resource "aws_autoscaling_group" "website" {
    name                 = "${var.service}-wp-${var.environment}-asg"
    launch_configuration = aws_launch_configuration.wp_launch_config.name

    vpc_zone_identifier = [
        var.private_subnet_a_id,
        var.private_subnet_b_id
    ]

    max_size                  = var.asg_max_size
    min_size                  = var.asg_min_size
    desired_capacity          = var.asg_desired_capacity
    health_check_grace_period = var.asg_health_check_grace_period
    health_check_type         = var.asg_health_check_type

    tags = list(
    map("key", "Name", "value", "${var.service}-wp-${var.environment}", "propagate_at_launch", true),
    map("key", "Service", "value", var.service, "propagate_at_launch", true),
    map("key", "Owner", "value", var.owner, "propagate_at_launch", true),
    map("key", "CostCentre", "value", var.cost_centre, "propagate_at_launch", true),
    map("key", "Terraform", "value", "true", "propagate_at_launch", true),
    map("key", "Patch Group", "value", var.patch_group_name, "propagate_at_launch", true)
    )
}

resource "aws_autoscaling_attachment" "website" {
    autoscaling_group_name = aws_autoscaling_group.website.id
    alb_target_group_arn   = aws_lb_target_group.website_public.arn
}
