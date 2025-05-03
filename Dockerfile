# Build stage
FROM node:20-alpine as build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy rest of the application
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built assets to nginx serve directory
COPY --from=build /app/dist /usr/share/nginx/html

# Add nginx configuration (optional, using default for now)
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]