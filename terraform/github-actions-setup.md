# Setting up IAM for GitHub Actions

## Using AWS CLI

### 1. Create IAM User
```powershell
aws iam create-user --user-name github-actions-user
```

### 2. Create Access Key
```powershell
aws iam create-access-key --user-name github-actions-user
```

### 3. Create IAM Policy
First, create a policy document:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "cloudfront:*"
            ],
            "Resource": [
                "arn:aws:s3:::my-react-app-bucket-20240504",
                "arn:aws:s3:::my-react-app-bucket-20240504/*",
                "arn:aws:cloudfront::your-account-id:distribution/your-distribution-id"
            ]
        }
    ]
}
```

Then attach the policy:
```powershell
aws iam put-user-policy `
    --user-name github-actions-user `
    --policy-name github-actions-policy `
    --policy-document file://github-actions-policy.json
```

### 4. Verify Setup
```powershell
# List user policies
aws iam list-user-policies --user-name github-actions-user

# Get policy details
aws iam get-user-policy --user-name github-actions-user --policy-name github-actions-policy
```

## Important Notes
- Store the access key output securely - you'll only see it once
- Add the credentials to GitHub repository secrets:
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY

## Cleanup Commands
```powershell
# Delete policy
aws iam delete-user-policy --user-name github-actions-user --policy-name github-actions-policy

# Delete access keys
aws iam delete-access-key --user-name github-actions-user --access-key-id YOURACCESSKEYID

# Delete user
aws iam delete-user --user-name github-actions-user
```