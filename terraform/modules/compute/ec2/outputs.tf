output "autoscaling_group_name" {
  description = "Name of the Auto Scaling group."
  value       = aws_autoscaling_group.this.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling group."
  value       = aws_autoscaling_group.this.arn
}

output "launch_template_id" {
  description = "ID of the launch template."
  value       = aws_launch_template.this.id
}

output "ami_id" {
  description = "AMI the instances are launched from."
  value       = local.ami_id
}

output "iam_role_name" {
  description = "Name of the instance IAM role. Attach extra policies to it from outside if needed."
  value       = aws_iam_role.this.name
}

output "iam_role_arn" {
  description = "ARN of the instance IAM role."
  value       = aws_iam_role.this.arn
}

output "instance_profile_arn" {
  description = "ARN of the instance profile."
  value       = aws_iam_instance_profile.this.arn
}
