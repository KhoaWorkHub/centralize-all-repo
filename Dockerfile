# Multi-stage build for Railway deployment
FROM maven:3.9.6-eclipse-temurin-21 AS backend-build
WORKDIR /app
COPY backend/pom.xml ./backend/
WORKDIR /app/backend
RUN mvn dependency:go-offline -B
COPY backend/src ./src
RUN mvn clean package -DskipTests

FROM node:18-alpine AS frontend-build
WORKDIR /app
COPY frontend/package*.json ./frontend/
WORKDIR /app/frontend
RUN npm ci --only=production
COPY frontend/ .
RUN npm run build

# Production runtime
FROM eclipse-temurin:21-jre-jammy

# Install nginx and curl
RUN apt-get update && \
    apt-get install -y nginx curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy backend jar
COPY --from=backend-build /app/backend/target/*.jar app.jar

# Copy frontend build to nginx directory
COPY --from=frontend-build /app/frontend/build /var/www/html

# Create nginx configuration for Railway
RUN echo 'server {\n\
    listen $PORT default_server;\n\
    server_name _;\n\
    root /var/www/html;\n\
    index index.html;\n\
    \n\
    # Handle client-side routing\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
    \n\
    # API proxy to backend\n\
    location /api/ {\n\
        proxy_pass http://localhost:8080;\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
    }\n\
    \n\
    # Webhook proxy to backend\n\
    location /webhook/ {\n\
        proxy_pass http://localhost:8080;\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
    }\n\
}' > /etc/nginx/sites-available/default

# Create startup script that runs both nginx and Spring Boot
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Use PORT environment variable from Railway\n\
export SERVER_PORT=${PORT:-8080}\n\
export NGINX_PORT=${PORT:-8080}\n\
\n\
# Update nginx config with actual port\n\
sed -i "s/\\$PORT/$NGINX_PORT/g" /etc/nginx/sites-available/default\n\
\n\
# Start nginx in background\n\
nginx -g "daemon off;" &\n\
NGINX_PID=$!\n\
\n\
# Start Spring Boot application in background\n\
java -Dserver.port=8080 -jar app.jar &\n\
JAVA_PID=$!\n\
\n\
# Function to handle shutdown\n\
shutdown() {\n\
    echo "Shutting down..."\n\
    kill $NGINX_PID $JAVA_PID 2>/dev/null || true\n\
    wait $NGINX_PID $JAVA_PID 2>/dev/null || true\n\
    exit 0\n\
}\n\
\n\
# Trap signals\n\
trap shutdown SIGTERM SIGINT\n\
\n\
# Wait for both processes\n\
wait\n\
' > /app/start.sh && chmod +x /app/start.sh

EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api/repos/stats || exit 1

CMD ["/app/start.sh"]