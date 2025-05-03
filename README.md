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
