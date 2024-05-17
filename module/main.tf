#SNS
resource "aws_sns_topic" "start_topic" {
  name = "start-topic"
  tags = var.tags
}

resource "aws_sns_topic_policy" "start_topic_policy" {
  arn    = aws_sns_topic.start_topic.arn
  policy = <<POLICY
    {
        "Version": "2008-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "events.amazonaws.com"
                },
                "Action": "sns:Publish",
                "Resource": "${aws_sns_topic.start_topic.arn}",
                "Condition": {
                    "ArnEquals": {
                        "aws:SourceArn": "${aws_cloudwatch_event_rule.start_event_rule.arn}"
                    }
                }
            }
        ]
    }
    POLICY  
}

resource "aws_sns_topic" "stop_topic" {
  name = "stop-topic"
  tags = var.tags
}

resource "aws_sns_topic_policy" "stop_topic_policy" {
  arn    = aws_sns_topic.stop_topic.arn
  policy = <<POLICY
    {
        "Version": "2008-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "events.amazonaws.com"
                },
                "Action": "sns:Publish",
                "Resource": "${aws_sns_topic.stop_topic.arn}",
                "Condition": {
                    "ArnEquals": {
                        "aws:SourceArn": "${aws_cloudwatch_event_rule.stop_event_rule.arn}"
                    }
                }
            }
        ]
    }
    POLICY  
}

#Event Bridge
resource "aws_cloudwatch_event_rule" "start_event_rule" {
  name                = "start-event-rule"
  schedule_expression = var.start_cron
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "start_event_target" {
  rule = aws_cloudwatch_event_rule.start_event_rule.name
  arn  = aws_sns_topic.start_topic.arn
  input = jsonencode({
    action = "start"
  })
}

resource "aws_cloudwatch_event_rule" "stop_event_rule" {
  name                = "stop-event-rule"
  schedule_expression = var.stop_cron
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "stop_event_target" {
  rule = aws_cloudwatch_event_rule.stop_event_rule.name
  arn  = aws_sns_topic.stop_topic.arn
  input = jsonencode({
    action = "stop"
  })
}


#API Gateway

data "aws_iam_policy_document" "apigateway_assume_role" {
  count = var.manual_endpoint ? 1 : 0
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "api_gateway_allow_sns_role" {
  count = var.manual_endpoint ? 1 : 0

  name = "start_stop_api_gateway_allow_sns_role"

  inline_policy {
    name = "start"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["sns:Publish"]
          Effect   = "Allow"
          Resource = [aws_sns_topic.start_topic.arn, aws_sns_topic.stop_topic.arn]
        }
      ]
    })
  }

  assume_role_policy = data.aws_iam_policy_document.apigateway_assume_role[0].json
  tags               = var.tags
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  count = var.manual_endpoint ? 1 : 0

  name           = "api-start-stop"
  api_key_source = "HEADER"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = var.tags
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  count = var.manual_endpoint ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  depends_on = [
    aws_api_gateway_integration_response.start_integration_response[0],
    aws_api_gateway_integration_response.stop_integration_response[0]
  ]
  lifecycle {
    create_before_destroy = true
  }

  # variables = {
  #   deployed_at = "${timestamp()}"
  # }
}

resource "aws_api_gateway_stage" "stage" {
  count = var.manual_endpoint ? 1 : 0

  deployment_id = aws_api_gateway_deployment.api_gateway_deployment[0].id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway[0].id
  stage_name    = "dev"
  tags          = var.tags
}

resource "aws_api_gateway_api_key" "api_key" {
  count = var.manual_endpoint ? 1 : 0

  name = "start-stop-key"
  tags = var.tags
}

resource "aws_api_gateway_usage_plan" "api_usage" {
  count = var.manual_endpoint ? 1 : 0

  name = "start-stop-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api_gateway[0].id
    stage  = aws_api_gateway_stage.stage[0].stage_name
  }

  depends_on = [aws_api_gateway_stage.stage[0]]
  tags       = var.tags
}

resource "aws_api_gateway_usage_plan_key" "api_key_usage_relation" {
  count = var.manual_endpoint ? 1 : 0

  key_id        = aws_api_gateway_api_key.api_key[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api_usage[0].id
}

# ##Start

resource "aws_api_gateway_resource" "start" {
  count = var.manual_endpoint ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  parent_id   = aws_api_gateway_rest_api.api_gateway[0].root_resource_id
  path_part   = "start"
}

resource "aws_api_gateway_method" "start_method" {
  count = var.manual_endpoint ? 1 : 0

  rest_api_id      = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id      = aws_api_gateway_resource.start[0].id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "start_integration" {
  count = var.manual_endpoint ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id = aws_api_gateway_resource.start[0].id
  http_method = aws_api_gateway_method.start_method[0].http_method

  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:sns:action/Publish"
  integration_http_method = "POST"
  credentials             = aws_iam_role.api_gateway_allow_sns_role[0].arn

  request_parameters = {
    "integration.request.header.Content-Type" : "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=Publish&TopicArn=$util.urlEncode('${aws_sns_topic.start_topic.arn}')&Message=$util.urlEncode($input.body)"
  }

}

resource "aws_api_gateway_method_response" "start_response" {
  count = var.manual_endpoint ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id = aws_api_gateway_resource.start[0].id
  http_method = aws_api_gateway_method.start_method[0].http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "start_integration_response" {
  count = var.manual_endpoint ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id = aws_api_gateway_resource.start[0].id
  http_method = aws_api_gateway_method.start_method[0].http_method
  status_code = aws_api_gateway_method_response.start_response[0].status_code

  response_templates = {
    "application/json" : "{\"body\": \"Message received. Starting Services.\"}"
  }
}

# ##Stop

resource "aws_api_gateway_resource" "stop" {
  count = var.manual_endpoint ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  parent_id   = aws_api_gateway_rest_api.api_gateway[0].root_resource_id
  path_part   = "stop"
}

resource "aws_api_gateway_method" "stop_method" {
  count = var.manual_endpoint ? 1 : 0

  rest_api_id      = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id      = aws_api_gateway_resource.stop[0].id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "stop_integration" {
  count = var.manual_endpoint ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id = aws_api_gateway_resource.stop[0].id
  http_method = aws_api_gateway_method.stop_method[0].http_method

  type = "AWS"
  uri  = "arn:aws:apigateway:${var.region}:sns:action/Publish"

  integration_http_method = "POST"
  credentials             = aws_iam_role.api_gateway_allow_sns_role[0].arn

  request_parameters = {
    "integration.request.header.Content-Type" : "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=Publish&TopicArn=$util.urlEncode('${aws_sns_topic.stop_topic.arn}')&Message=$util.urlEncode($input.body)"
  }
}

resource "aws_api_gateway_method_response" "stop_response" {
  count = var.manual_endpoint ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id = aws_api_gateway_resource.stop[0].id
  http_method = aws_api_gateway_method.stop_method[0].http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "stop_integration_response" {
  count = var.manual_endpoint ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api_gateway[0].id
  resource_id = aws_api_gateway_resource.stop[0].id
  http_method = aws_api_gateway_method.stop_method[0].http_method
  status_code = aws_api_gateway_method_response.stop_response[0].status_code

  response_templates = {
    "application/json" : "{\"body\": \"Message received. Stopping Services.\"}"
  }
}
