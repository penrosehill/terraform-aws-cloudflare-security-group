resource "aws_lambda_permission" "allow_cloudwatch" {
  count         = var.enabled ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update-ips[count.index].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudflare-update-schedule[count.index].arn
}

resource "aws_cloudwatch_event_rule" "cloudflare-update-schedule" {
  count       = var.enabled ? 1 : 0
  name        = "cloudflare-update-schedule"
  description = "Update cloudflare ips every day"

  schedule_expression = var.schedule_expression
}


resource "aws_cloudwatch_event_target" "cloudflare-update-schedule" {
  count = var.enabled ? 1 : 0
  rule  = aws_cloudwatch_event_rule.cloudflare-update-schedule[count.index].name
  arn   = aws_lambda_function.update-ips[count.index].arn
}
