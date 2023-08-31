locals {
  names      = "${var.env}-${var.components}"
  tags       = merge(var.tags, { tf-module = "apps" }, { env = var.env })
  parameters = concat(var.parameters,[var.components])
parameters_eff = [for i in local.parameters : "arn:aws:ssm:us-east-1:120752001195:parameter/${i}.${var.env}.*"]

}