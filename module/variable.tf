variable "enable" {
  type    = bool
  default = false
}

variable "manual_endpoint" {
  type    = bool
  default = false
}

variable "region" {
  type = string
}

variable "tag" {
  type = object({
    key   = string
    value = string
  })
}

variable "start_cron" {
  type = string
}

variable "stop_cron" {
  type = string
}

variable "asg" {
  type    = bool
  default = false
}

variable "rds" {
  type    = bool
  default = false
}

variable "ecs" {
  type    = bool
  default = false
}

variable "ec2" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}