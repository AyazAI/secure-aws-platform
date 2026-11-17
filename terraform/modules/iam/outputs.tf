output "execution_role_arn" {
  description = "ARN of the ECS task execution role."
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role. The demo task role has no permissions."
  value       = aws_iam_role.task.arn
}
