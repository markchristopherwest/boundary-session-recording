# output "activation_token_downstream_egress" {
#   value = boundary_worker.downstream_egress.controller_generated_activation_token
# }

# output "activation_token_upstream_ingress" {
#   value = boundary_worker.upstream_ingress.controller_generated_activation_token
# }

output "your_worker_downstream" {
  value = aws_instance.downstream_egress.public_ip
}

output "your_worker_upstream" {
  value = aws_instance.upstream_ingress.public_ip
}
