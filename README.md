# React Vite TypeScript Project

This is a React application built with Vite and TypeScript.

## Scripts

The following npm scripts are available:

- `npm run dev` - Start development server
- `npm run build` - Build for production (TypeScript compilation + Vite build)
- `npm run lint` - Run ESLint
- `npm run preview` - Preview production build on port 5000

## Docker Support

This project includes Docker support. The application runs on port 5000 and is configured to accept connections from any network interface using the `--host` flag.

### Available Scripts in Docker

To build and run the application in Docker:

```bash
# Build the Docker image
docker build -t react-app .

# Run the container
docker run -p 5000:5000 react-app
```

## Dependencies

### Main Dependencies
- React: ^19.0.0
- React DOM: ^19.0.0

### Development Dependencies
- TypeScript: ~5.7.2
- Vite: ^6.3.1
- ESLint: ^9.22.0
- Various TypeScript and React related plugins

## Development

The project uses:
- TypeScript for type safety
- ESLint for code linting
- Vite for fast development and building

## Expanding the ESLint configuration

If you are developing a production application, we recommend updating the configuration to enable type-aware lint rules:

```js
export default tseslint.config({
  extends: [
    // Remove ...tseslint.configs.recommended and replace with this
    ...tseslint.configs.recommendedTypeChecked,
    // Alternatively, use this for stricter rules
    ...tseslint.configs.strictTypeChecked,
    // Optionally, add this for stylistic rules
    ...tseslint.configs.stylisticTypeChecked,
  ],
  languageOptions: {
    // other options...
    parserOptions: {
      project: ['./tsconfig.node.json', './tsconfig.app.json'],
      tsconfigRootDir: import.meta.dirname,
    },
  },
})
```

You can also install [eslint-plugin-react-x](https://github.com/Rel1cx/eslint-react/tree/main/packages/plugins/eslint-plugin-react-x) and [eslint-plugin-react-dom](https://github.com/Rel1cx/eslint-react/tree/main/packages/plugins/eslint-plugin-react-dom) for React-specific lint rules:

```js
// eslint.config.js
import reactX from 'eslint-plugin-react-x'
import reactDom from 'eslint-plugin-react-dom'

export default tseslint.config({
  plugins: {
    // Add the react-x and react-dom plugins
    'react-x': reactX,
    'react-dom': reactDom,
  },
  rules: {
    // other rules...
    // Enable its recommended typescript rules
    ...reactX.configs['recommended-typescript'].rules,
    ...reactDom.configs.recommended.rules,
  },
})
```

# React App Deployment with AWS ECS and CodePipeline

This guide explains how to deploy a React application using AWS ECS, CodePipeline, and Docker.

## Prerequisites

- AWS Account (Free Tier eligible)
- GitHub Account
- Node.js installed
- Docker Desktop installed
- AWS CLI installed
- Terraform installed

## Project Structure

```
.
├── terraform/
│   ├── main.tf                # Main Terraform configuration
│   └── .terraform/            # Terraform plugins and modules
├── .github/
│   └── workflows/
│       └── deploy.yml         # GitHub Actions workflow
├── src/                       # React application source code
├── Dockerfile                 # Docker configuration
├── buildspec.yml             # AWS CodeBuild specification
└── README.md                 # This file
```

## Step 1: Local Setup

1. Clone the repository:
```powershell
git clone https://github.com/mc-aravind/my-app.git
cd my-app
```

2. Create a new branch:
```powershell
git checkout -b feature/docker-container-ecr
```

3. Install dependencies:
```powershell
npm install
```

## Step 2: Docker Configuration

1. Create Dockerfile:
```dockerfile
FROM node:18-alpine as build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

2. Create buildspec.yml:
```yaml
version: 0.2
phases:
  pre_build:
    commands:
      - aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${COMMIT_HASH:=latest}
  build:
    commands:
      - docker build -t $ECR_REPOSITORY_URI:$IMAGE_TAG .
  post_build:
    commands:
      - docker push $ECR_REPOSITORY_URI:$IMAGE_TAG
      - printf '[{"name":"react-app","imageUri":"%s"}]' $ECR_REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json
artifacts:
  files:
    - imagedefinitions.json
```

## Step 3: AWS Infrastructure Setup

1. Initialize Terraform:
```powershell
cd terraform
terraform init
```

2. Apply Terraform configuration:
```powershell
terraform apply -auto-approve
```

3. Note the outputs:
- ECR Repository URL
- CodePipeline URL
- GitHub Connection URL

## Step 4: GitHub Connection Setup

1. Open the GitHub Connection URL from Terraform outputs
2. Click "Update pending connection"
3. Complete GitHub authorization
4. Select your repository

## Step 5: Pipeline Configuration

The pipeline consists of three stages:
1. Source: Pulls code from GitHub
2. Build: Creates Docker image and pushes to ECR
3. Deploy: Deploys container to ECS

## Step 6: Deployment

1. Commit and push your changes:
```powershell
git add .
git commit -m "Initial container setup"
git push origin feature/docker-container-ecr
```

2. Monitor the pipeline:
- Open AWS Console
- Go to CodePipeline
- Watch the pipeline progress

## Step 7: Verify Deployment

1. Open AWS Console
2. Navigate to ECS → Clusters → react-app-cluster
3. Click on the running task
4. Find the public IP
5. Access your app at http://<public-ip>

## Common Issues and Solutions

1. **Pipeline Source Error**:
   - Verify GitHub connection is completed
   - Check branch name matches exactly

2. **Build Error**:
   - Verify Dockerfile is in repository root
   - Check buildspec.yml syntax

3. **Deploy Error**:
   - Check imagedefinitions.json is created
   - Verify ECS service is running

## Cleanup

To avoid charges, remove all resources:
```powershell
terraform destroy -auto-approve
```

## AWS Free Tier Usage

This setup uses:
- ECR: 500MB storage per month
- ECS: Fargate minimal configuration
- CloudWatch: 5GB logs per month
- CodePipeline: One active pipeline

Monitor AWS Billing Dashboard to avoid unexpected charges.

## Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline)
- [Terraform Documentation](https://www.terraform.io/docs)

## Support

For issues and questions:
1. Check AWS CloudWatch logs
2. Review pipeline execution details
3. Check ECS task status
