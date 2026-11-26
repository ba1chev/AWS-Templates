output "lb_arn" {
  description = "ARN of the load balancer."
  value       = aws_lb.this.arn
}

output "lb_dns_name" {
  description = "DNS name of the load balancer."
  value       = aws_lb.this.dns_name
}

output "lb_zone_id" {
  description = "Hosted zone ID of the load balancer (for Route 53 alias records)."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group. Pass it to the EC2 module."
  value       = aws_lb_target_group.this.arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener."
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (null when no certificate is set)."
  value       = try(aws_lb_listener.https[0].arn, null)
}
