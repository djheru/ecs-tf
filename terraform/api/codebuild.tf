resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "codecommit:GitPull"
        ],
        Effect   = "Allow",
        Resource = data.aws_codecommit_repository.ecs_ecr_repository.arn
      },
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage"
        ],
        Effect   = "Allow",
        Resource = aws_ecr_repository.ecs_ecr_repository.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ],
        Effect = "Allow",
        Resource = [
          aws_s3_bucket.artifact_store.arn,
          "${aws_s3_bucket.artifact_store.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_codebuild_project" "polaris_api_build" {
  name          = "polaris-api-build"
  description   = "Build and push Docker image for Polaris API"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 15 # in minutes
  source {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${var.app_name}-log-group"
      stream_name = "${var.app_name}-log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.artifact_store.id}/build-log"
    }
  }


  artifacts {
    type = "CODEPIPELINE"
    name = "polaris-api"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.ecs_ecr_repository.repository_url
    }
    # Add additional environment variables if needed
  }
}
