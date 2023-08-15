data "aws_codecommit_repository" "ecs_ecr_repository" {
  repository_name = "${var.app_name}-prototype"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:ListBranches",
          "codecommit:GetRepository",
          "codecommit:ListRepositories",
          "codecommit:PollForSourceChanges"
        ],
        Effect   = "Allow",
        Resource = data.aws_codecommit_repository.ecs_ecr_repository.arn
      },
      {
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ],
        Effect   = "Allow",
        Resource = aws_codebuild_project.polaris_api_build.arn
      },
      {
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ],
        Effect   = "Allow",
        Resource = aws_codedeploy_app.polaris_api_app.arn
      },
      {
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ],
        Effect   = "Allow",
        Resource = aws_ecr_repository.ecs_ecr_repository.arn
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket"
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

resource "aws_codepipeline" "polaris_api_pipeline" {
  name     = "polaris-api-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_store.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = data.aws_codecommit_repository.ecs_ecr_repository.repository_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "BuildAndPush"

    action {
      name             = "BuildAndPush"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.polaris_api_build.name
      }
    }
  }

  stage {
    name = "DeployToECS"

    action {
      name            = "DeployToECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.polaris_api_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.polaris_api_deployment_group.id
      }
    }
  }

  stage {
    name = "RunMigration"

    action {
      name            = "RunMigration"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName    = aws_ecs_cluster.ecs_cluster.name
        TaskDefinition = aws_ecs_task_definition.migration_task.arn
        LaunchType     = "FARGATE"
        # Additional configurations for networking, ECS task role, etc.
      }
    }
  }

}

resource "aws_s3_bucket" "artifact_store" {
  bucket = "polaris-api-artifacts"
}

resource "aws_s3_bucket_acl" "artifact_store_acl" {
  bucket = aws_s3_bucket.artifact_store.bucket
  acl    = "private"
}
