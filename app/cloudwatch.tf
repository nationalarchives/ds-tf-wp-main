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
                    [ "AWS/ApplicationELB", "ActiveConnectionCount", "LoadBalancer", "${aws_lb.website_public.arn_suffix}" ],
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
                    [ "AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "${aws_lb.website_public.arn_suffix}" ],
                    [ ".", "HTTPCode_Target_2XX_Count", ".", "." ]
                ],
                "region": "eu-west-2",
                "title": "HTTP Status Codes",
                "period": 300
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
                    [ "AWS/EC2", "NetworkIn" ],
                    [ ".", "NetworkOut" ]
                ],
                "region": "eu-west-2",
                "title": "EC2 Network"
            }
        },
        {
            "type": "text",
            "x": 0,
            "y": 15,
            "width": 24,
            "height": 1,
            "properties": {
                "markdown": "\n## Disk Activity\n"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 16,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/EFS", "StorageBytes", "StorageClass", "Total", "FileSystemId", "${aws_efs_file_system.website.id}" ]
                ],
                "region": "eu-west-2",
                "title": "EFS Storage"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 16,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/EFS", "TotalIOBytes", "FileSystemId", "${aws_efs_file_system.website.id}" ]
                ],
                "region": "eu-west-2",
                "title": "EFS Total IO"
            }
        }
    ]
}
EOF
}
