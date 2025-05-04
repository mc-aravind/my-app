# Create IAM user for GitHub Actions
resource "aws_iam_user" "github_actions" {
  name = "github-actions-user"
}

# Create IAM policy for S3 and CloudFront access
resource "aws_iam_user_policy" "github_actions" {
  name = "github-actions-policy"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "cloudfront:*"
        ]
        Resource = [
          aws_s3_bucket.react_app.arn,
          "${aws_s3_bucket.react_app.arn}/*",
          aws_cloudfront_distribution.cdn.arn
        ]
      }
    ]
  })
}
