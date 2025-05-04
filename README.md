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

# React App Docker ECS Deployment

This project demonstrates deploying a React application to AWS ECS using Docker containers and GitHub Actions for CI/CD.

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions workflow
├── terraform/
│   ├── ecr.tf             # ECR repository configuration
│   ├── ecs.tf             # ECS cluster and service configuration
│   └── main.tf            # Core infrastructure
├── Dockerfile             # Container configuration
├── nginx.conf            # Nginx server configuration
└── README.md             # This file
```

## Prerequisites

- AWS Account
- GitHub Account
- Node.js 18+
- Docker Desktop
- AWS CLI
- Terraform

## Local Development

1. Install dependencies:
```bash
npm install
```

2. Start development server:
```bash
npm run dev
```

## Docker Build

Build the container locally:
```bash
docker build -t react-app .
docker run -p 80:80 react-app
```

## Infrastructure Setup

1. Initialize Terraform:
```powershell
cd terraform
terraform init
```

2. Apply infrastructure:
```powershell
terraform apply -auto-approve
```

## GitHub Actions Configuration

Required secrets in GitHub repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Deployment

Push to the `feature/docker-container-ecr` branch to trigger deployment:
```bash
git push origin feature/docker-container-ecr
```

The workflow will:
1. Build the React application
2. Create Docker image
3. Push to AWS ECR
4. Deploy to ECS

## Infrastructure Components

- **ECR Repository**: Stores Docker images
- **ECS Cluster**: Runs containerized application
- **Application Load Balancer**: Routes traffic
- **CloudWatch Logs**: Application monitoring

## Security Groups

- **Load Balancer**: Allows inbound HTTP (port 80)
- **ECS Tasks**: Allows traffic from ALB

## Monitoring

Access logs in CloudWatch:
1. Open AWS Console
2. Navigate to CloudWatch > Log Groups
3. Find `/ecs/react-app`

## Cleanup

Remove all resources:
```powershell
terraform destroy -auto-approve
```

## Contributing

1. Create a feature branch
2. Make changes
3. Submit pull request

## Troubleshooting

1. **Container not starting**:
   - Check CloudWatch logs
   - Verify security group rules
   - Check task definition

2. **Deploy failing**:
   - Verify GitHub secrets
   - Check Actions logs
   - Validate ECR permissions

## License

MIT

## Author

Your Name
