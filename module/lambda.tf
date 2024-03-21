#Common
data "aws_iam_policy" "lambda_basic_execution_role_policy" {
  name = "AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


#RDS

## Permissions
resource "aws_iam_role" "rds_lambda_iam_role" {
  count = var.rds ? 1 : 0

  name_prefix         = "start-stop-rds-lambda"
  managed_policy_arns = [data.aws_iam_policy.lambda_basic_execution_role_policy.arn]
  inline_policy {
    name = "start"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["rds:DescribeDBInstances", "rds:StartDBInstance", "rds:StopDBInstance", "rds:DescribeDBClusters", "rds:StartDBCluster", "rds:StopDBCluster"]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = var.tags
}

## Start
resource "aws_lambda_function" "start_rds_lambda_function" {
  count = var.rds ? 1 : 0

  function_name    = "start-rds"
  filename         = data.archive_file.start_rds_lambda_zip_file[0].output_path
  source_code_hash = data.archive_file.start_rds_lambda_zip_file[0].output_base64sha256
  handler          = "app.lambda_handler"
  role             = aws_iam_role.rds_lambda_iam_role[0].arn
  runtime          = "python3.8"
  environment {
    variables = {
      "TAG_KEY"   = var.tag.key
      "TAG_VALUE" = var.tag.value
    }
  }
    tags = var.tags

}

data "archive_file" "start_rds_lambda_zip_file" {
  count = var.rds ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/src/start-rds/app.py"
  output_path = "${path.module}/zip/start-rds.zip"
}

resource "aws_sns_topic_subscription" "start_rds_lambda_subscription" {
  count = var.rds ? 1 : 0
  topic_arn = aws_sns_topic.start_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.start_rds_lambda_function[0].arn
}

resource "aws_lambda_permission" "start_rds_lambda_subscription_permission" {
  count = var.rds ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_rds_lambda_function[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.start_topic.arn
}

## Stop

resource "aws_lambda_function" "stop_rds_lambda_function" {
  count = var.rds ? 1 : 0

  function_name    = "stop-rds"
  filename         = data.archive_file.stop_rds_lambda_zip_file[0].output_path
  source_code_hash = data.archive_file.stop_rds_lambda_zip_file[0].output_base64sha256
  handler          = "app.lambda_handler"
  role             = aws_iam_role.rds_lambda_iam_role[0].arn
  runtime          = "python3.8"
  environment {
    variables = {
      "TAG_KEY"   = var.tag.key
      "TAG_VALUE" = var.tag.value
    }
  }
    tags = var.tags

}

data "archive_file" "stop_rds_lambda_zip_file" {
  count = var.rds ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/src/stop-rds/app.py"
  output_path = "${path.module}/zip/stop-rds.zip"
}

resource "aws_sns_topic_subscription" "stop_rds_lambda_subscription" {
  count = var.rds ? 1 : 0
  topic_arn = aws_sns_topic.stop_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.stop_rds_lambda_function[0].arn
}

resource "aws_lambda_permission" "stop_rds_lambda_subscription_permission" {
  count = var.rds ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_rds_lambda_function[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.stop_topic.arn
}






#EC2

## Permissions
resource "aws_iam_role" "ec2_lambda_iam_role" {
  count               = var.ec2 ? 1 : 0
  name_prefix         = "start-stop-ec2-lambda"
  managed_policy_arns = [data.aws_iam_policy.lambda_basic_execution_role_policy.arn]
  inline_policy {
    name = "start"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["ec2:DescribeInstances", "ec2:StartInstances", "ec2:StopInstances"]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

    tags = var.tags

}

## Start

resource "aws_lambda_function" "start_ec2_lambda_function" {
  count = var.ec2 ? 1 : 0
  timeout = 20
  function_name    = "start-ec2"
  filename         = data.archive_file.start_ec2_lambda_zip_file[0].output_path
  source_code_hash = data.archive_file.start_ec2_lambda_zip_file[0].output_base64sha256
  handler          = "app.lambda_handler"
  role             = aws_iam_role.ec2_lambda_iam_role[0].arn
  runtime          = "python3.8"
  environment {
    variables = {
      "TAG_KEY"   = var.tag.key
      "TAG_VALUE" = var.tag.value
    }
  }
    tags = var.tags

}

data "archive_file" "start_ec2_lambda_zip_file" {
  count = var.ec2 ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/src/start-ec2/app.py"
  output_path = "${path.module}/zip/start-ec2.zip"
}

resource "aws_sns_topic_subscription" "start_ec2_lambda_subscription" {
  count = var.ec2 ? 1 : 0
  topic_arn = aws_sns_topic.start_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.start_ec2_lambda_function[0].arn
}

resource "aws_lambda_permission" "start_ec2_lambda_subscription_permission" {
  count = var.ec2 ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_ec2_lambda_function[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.start_topic.arn
}

## Stop

resource "aws_lambda_function" "stop_ec2_lambda_function" {
  count = var.ec2 ? 1 : 0
  timeout = 20
  function_name    = "stop-ec2"
  filename         = data.archive_file.stop_ec2_lambda_zip_file[0].output_path
  source_code_hash = data.archive_file.stop_ec2_lambda_zip_file[0].output_base64sha256
  handler          = "app.lambda_handler"
  role             = aws_iam_role.ec2_lambda_iam_role[0].arn
  runtime          = "python3.8"
  environment {
    variables = {
      "TAG_KEY"   = var.tag.key
      "TAG_VALUE" = var.tag.value
    }
  }
  tags = var.tags
}


data "archive_file" "stop_ec2_lambda_zip_file" {
  count = var.ec2 ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/src/stop-ec2/app.py"
  output_path = "${path.module}/zip/stop-ec2.zip"
}

resource "aws_sns_topic_subscription" "stop_ec2_lambda_subscription" {
  count = var.ec2 ? 1 : 0
  topic_arn = aws_sns_topic.stop_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.stop_ec2_lambda_function[0].arn
}

resource "aws_lambda_permission" "stop_ec2_lambda_subscription_permission" {
  count = var.ec2 ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_ec2_lambda_function[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.stop_topic.arn
}


#ECS

## Permissions
resource "aws_iam_role" "ecs_lambda_iam_role" {
  count = var.ecs ? 1 : 0

  name_prefix         = "start-stop-ecs-lambda"
  managed_policy_arns = [data.aws_iam_policy.lambda_basic_execution_role_policy.arn]
  inline_policy {
    name = "start"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
            "ecs:ListClusters", 
            "ecs:ListServices", 
            "ecs:DescribeServices", 
            "ecs:UpdateService", 
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags = var.tags
}

## Start

resource "aws_lambda_function" "start_ecs_lambda_function" {
  count = var.ecs ? 1 : 0

  function_name    = "start-ecs"
  filename         = data.archive_file.start_ecs_lambda_zip_file[0].output_path
  source_code_hash = data.archive_file.start_ecs_lambda_zip_file[0].output_base64sha256
  handler          = "app.lambda_handler"
  role             = aws_iam_role.ecs_lambda_iam_role[0].arn
  runtime          = "python3.8"
  environment {
    variables = {
      "TAG_KEY"   = var.tag.key
      "TAG_VALUE" = var.tag.value
    }
  }
  tags = var.tags
}

data "archive_file" "start_ecs_lambda_zip_file" {
  count = var.ecs ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/src/start-ecs/app.py"
  output_path = "${path.module}/zip/start-ecs.zip"
}

resource "aws_sns_topic_subscription" "start_ecs_lambda_subscription" {
  count = var.ecs ? 1 : 0
  topic_arn = aws_sns_topic.start_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.start_ecs_lambda_function[0].arn
}

resource "aws_lambda_permission" "start_ecs_lambda_subscription_permission" {
  count = var.ecs ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_ecs_lambda_function[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.start_topic.arn
}

## Stop

resource "aws_lambda_function" "stop_ecs_lambda_function" {
  count = var.ecs ? 1 : 0

  function_name    = "stop-ecs"
  filename         = data.archive_file.stop_ecs_lambda_zip_file[0].output_path
  source_code_hash = data.archive_file.stop_ecs_lambda_zip_file[0].output_base64sha256
  handler          = "app.lambda_handler"
  role             = aws_iam_role.ecs_lambda_iam_role[0].arn
  runtime          = "python3.8"
  environment {
    variables = {
      "TAG_KEY"   = var.tag.key
      "TAG_VALUE" = var.tag.value
    }
  }
  tags = var.tags
}

data "archive_file" "stop_ecs_lambda_zip_file" {
  count = var.ecs ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/src/stop-ecs/app.py"
  output_path = "${path.module}/zip/stop-ecs.zip"
}

resource "aws_sns_topic_subscription" "stop_ecs_lambda_subscription" {
  count = var.ecs ? 1 : 0
  topic_arn = aws_sns_topic.stop_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.stop_ecs_lambda_function[0].arn
}

resource "aws_lambda_permission" "stop_ecs_lambda_subscription_permission" {
  count = var.ecs ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_ecs_lambda_function[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.stop_topic.arn
}





#ASG

## Permissions

resource "aws_iam_role" "asg_lambda_iam_role" {
  count               = var.asg ? 1 : 0
  name_prefix         = "start-stop-asg-lambda"
  managed_policy_arns = [data.aws_iam_policy.lambda_basic_execution_role_policy.arn]
  inline_policy {
    name = "start"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["autoscaling:UpdateAutoScalingGroup", "autoscaling:DescribeAutoScalingGroups"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags = var.tags
}   

## Start
resource "aws_lambda_function" "start_asg_lambda_function" {
  count               = var.asg ? 1 : 0

  function_name    = "start-asg"
  filename         = data.archive_file.start_asg_lambda_zip_file[0].output_path
  source_code_hash = data.archive_file.start_asg_lambda_zip_file[0].output_base64sha256
  handler          = "app.lambda_handler"
  role             = aws_iam_role.asg_lambda_iam_role[0].arn
  runtime          = "python3.8"
  environment {
    variables = {
      "TAG_KEY"   = var.tag.key
      "TAG_VALUE" = var.tag.value,
    }
  }
  tags = var.tags
}

data "archive_file" "start_asg_lambda_zip_file" {
  count               = var.asg ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/src/start-asg/app.py"
  output_path = "${path.module}/zip/start-asg.zip"
}

resource "aws_sns_topic_subscription" "start_asg_lambda_subscription" {
  count               = var.asg ? 1 : 0
  topic_arn = aws_sns_topic.start_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.start_asg_lambda_function[0].arn
}

resource "aws_lambda_permission" "start_asg_lambda_subscription_permission" {
  count               = var.asg ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_asg_lambda_function[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.start_topic.arn
}

## Stop

resource "aws_lambda_function" "stop_asg_lambda_function" {
  count               = var.asg ? 1 : 0

  function_name    = "stop-asg"
  filename         = data.archive_file.stop_asg_lambda_zip_file[0].output_path
  source_code_hash = data.archive_file.stop_asg_lambda_zip_file[0].output_base64sha256
  handler          = "app.lambda_handler"
  role             = aws_iam_role.asg_lambda_iam_role[0].arn
  runtime          = "python3.8"
  environment {
    variables = {
      "TAG_KEY"   = var.tag.key
      "TAG_VALUE" = var.tag.value,
    }
  }
  tags = var.tags
}

data "archive_file" "stop_asg_lambda_zip_file" {
  count               = var.asg ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/src/stop-asg/app.py"
  output_path = "${path.module}/zip/stop-asg.zip"
}

resource "aws_sns_topic_subscription" "stop_asg_lambda_subscription" {
  count               = var.asg ? 1 : 0
  topic_arn = aws_sns_topic.stop_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.stop_asg_lambda_function[0].arn
}

resource "aws_lambda_permission" "stop_asg_lambda_subscription_permission" {
  count               = var.asg ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_asg_lambda_function[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.stop_topic.arn
}