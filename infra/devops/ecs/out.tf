output "web_endpoint" {
  value = "http://${aws_lb.devops-ninja-lb.dns_name}/healthcheck"
  description = "hit this url to access web server"
}

#output "ecr_repo_url" {
  #value = aws_ecr_repository.hello_world.repository_url
  #description = "url where the docker image is to be pushed"
#}