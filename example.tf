module "start_stop" {
  source = "./module"

  region = "us-east-1"

  enable          = true
  manual_endpoint = true

  start_cron = "cron(0 10 ? * MON-FRI *)"
  stop_cron  = "cron(0 22 ? * MON-FRI *)"

  tag = {
    key   = "start-stop"
    value = "true"
  }

  asg = true
  ecs = true
  rds = true
  ec2 = true

  tags = {}
}