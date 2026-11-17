output "alb_arn" {
  description = "ARN of the load balancer."
  value       = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix used by CloudWatch ALB metrics."
  value       = aws_lb.this.arn_suffix
}

output "alb_dns_name" {
  description = "Public DNS name of the load balancer."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the load balancer, for an alias record."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group."
  value       = aws_lb_target_group.this.arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix used by CloudWatch target-group metrics."
  value       = aws_lb_target_group.this.arn_suffix
}

output "listener_arns" {
  description = "Listener ARNs. The ECS service waits on these so the target group is attached before tasks start."
  value = compact([
    one(aws_lb_listener.http[*].arn),
    one(aws_lb_listener.http_redirect[*].arn),
    one(aws_lb_listener.https[*].arn),
  ])
}
