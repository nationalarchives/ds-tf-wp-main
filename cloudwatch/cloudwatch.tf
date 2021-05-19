resource "aws_cloudwatch_dashboard" "app" {
    dashboard_name = "${var.service}-wp-dashboard"

    dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "text",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 1,
            "properties": {
                "markdown": "\n# Wordpress Servers\n"
            }
        },
        {
            "type": "text",
            "x": 0,
            "y": 1,
            "width": 24,
            "height": 1,
            "properties": {
                "markdown": "\n## Web Activity\n"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 2,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "ActiveConnectionCount", "LoadBalancer", "${var.website_internal_lb_arn_suffix}" ],
                    [ ".", "RequestCount", ".", "." ]
                ],
                "region": "eu-west-2",
                "title": "Connections and Requests"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 2,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "${var.website_internal_lb_arn_suffix}" ],
                    [ ".", "HTTPCode_Target_2XX_Count", ".", "." ]
                ],
                "region": "eu-west-2",
                "title": "HTTP Status Codes"
            }
        },
        {
            "type": "text",
            "x": 0,
            "y": 8,
            "width": 24,
            "height": 1,
            "properties": {
                "markdown": "\n## Server Stats\n"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 9,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/EC2", "CPUUtilization" ]
                ],
                "region": "eu-west-2",
                "title": "EC2 CPU"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 9,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ { "expression": "SEARCH(' {CWAgent, InstanceId} MetricName=\"mem_used_percent\" ', 'Average', 300)", "label": "MemoryUsedPercent", "id": "e1" } ]
                ],
                "region": "eu-west-2",
                "title": "Instance memory used"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 15,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/EC2", "NetworkIn" ],
                    [ ".", "NetworkOut" ]
                ],
                "region": "eu-west-2",
                "title": "EC2 Network"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 15,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "ReadLatency", "DBInstanceIdentifier", "${var.website_main_rds_identifier}" ],
                    [ ".", "CPUUtilization", ".", "." ]
                ],
                "region": "eu-west-2",
                "title": "RDS Stats"
            }
        },
        {
            "type": "text",
            "x": 0,
            "y": 21,
            "width": 24,
            "height": 1,
            "properties": {
                "markdown": "\n## Disk Activity\n"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 22,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/EFS", "StorageBytes", "StorageClass", "Total", "FileSystemId", "${var.website_efs_id}" ]
                ],
                "region": "eu-west-2",
                "title": "EFS Storage"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 22,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/EFS", "TotalIOBytes", "FileSystemId", "${var.website_efs_id}" ]
                ],
                "region": "eu-west-2",
                "title": "EFS Total IO"
            }
        }
    ]
}
EOF
}

resource "aws_s3_bucket_object" "cloudwatch_agent_config" {
    bucket  = var.deployment_s3_bucket
    key     = "${var.service}/cloudwatch/cloudwatch-agent-config.json"
    source  = "${path.module}/cloudwatch-agent-config.json"
    etag    = filemd5("${path.module}/cloudwatch-agent-config.json")
}
