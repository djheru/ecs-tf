resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-role"

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ],
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy" "codedeploy_policy" {
  name = "codedeploy-policy"
  role = aws_iam_role.codedeploy_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ecs:DescribeServices",
          "ecs:CreateTaskSet",
          "ecs:UpdateServicePrimaryTaskSet",
          "ecs:DeleteTaskSet",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:ModifyRule",
          "lambda:InvokeFunction",
          "cloudwatch:DescribeAlarms"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_codedeploy_app" "polaris_api_app" {
  name             = "polaris-api-app"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "polaris_api_deployment_group" {
  app_name               = aws_codedeploy_app.polaris_api_app.name
  deployment_group_name  = "polaris-api-deployment-group"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce" # Choose the appropriate deployment strategy
  service_role_arn       = aws_iam_role.codedeploy_role.arn # IAM role with necessary permissions

  ecs_service {
    cluster_name = aws_ecs_cluster.ecs_cluster.name
    service_name = aws_ecs_service.ecs_service.name
  }

  # Additional configurations for alarms, triggers, etc.
}
