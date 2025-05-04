resource "aws_ecr_repository" "app" {
  name = "react-app"
  force_delete = true
}

output "repository_url" {
  value = aws_ecr_repository.app.repository_url
}