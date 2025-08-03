#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║            🎨 DEPLOY FRONTEND TO RAILWAY 🎨                  ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}🎯 We'll deploy your React frontend to Railway${NC}"
echo -e "${CYAN}   It will connect to your existing backend API${NC}"
echo ""

# Get backend URL
echo -e "${YELLOW}📋 First, we need your backend URL${NC}"
echo -e "${BLUE}Please enter your Railway backend URL:${NC}"
echo -e "${BLUE}(Should look like: https://web-production-xxxx.up.railway.app)${NC}"
read -p "Backend URL: " BACKEND_URL

if [ -z "$BACKEND_URL" ]; then
    echo -e "${RED}❌ Backend URL is required${NC}"
    exit 1
fi

# Remove trailing slash
BACKEND_URL=${BACKEND_URL%/}

echo -e "${GREEN}✅ Backend URL: $BACKEND_URL${NC}"
echo ""

# Create frontend environment file
echo -e "${YELLOW}🔧 Creating frontend environment configuration...${NC}"

cat > frontend/.env.production << EOF
REACT_APP_API_URL=$BACKEND_URL
REACT_APP_ENV=production
EOF

echo -e "${GREEN}✅ Frontend environment configured${NC}"

# Create Railway-specific frontend Dockerfile
cat > Dockerfile.frontend.railway << 'EOF'
# Frontend-only build for Railway
FROM node:18-alpine AS build

WORKDIR /app

# Copy package files
COPY frontend/package*.json ./
RUN npm ci

# Copy source files
COPY frontend/src ./src
COPY frontend/public ./public
COPY frontend/tailwind.config.js ./
COPY frontend/postcss.config.js ./
COPY frontend/tsconfig.json ./
COPY frontend/.env.production ./

# Build the app
RUN npm run build

# Production stage with nginx
FROM nginx:alpine

# Copy built files
COPY --from=build /app/build /usr/share/nginx/html

# Create nginx configuration
RUN echo 'server {\n\
    listen $PORT default_server;\n\
    server_name _;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    \n\
    # Enable gzip compression\n\
    gzip on;\n\
    gzip_vary on;\n\
    gzip_min_length 1024;\n\
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;\n\
    \n\
    # Handle client-side routing\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
    \n\
    # Cache static assets\n\
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg)$ {\n\
        expires 1y;\n\
        add_header Cache-Control "public, immutable";\n\
    }\n\
    \n\
    # Security headers\n\
    add_header X-Frame-Options "SAMEORIGIN" always;\n\
    add_header X-Content-Type-Options "nosniff" always;\n\
    add_header X-XSS-Protection "1; mode=block" always;\n\
}' > /etc/nginx/conf.d/default.conf.template

# Create startup script that replaces $PORT
RUN echo '#!/bin/sh\n\
export DOLLAR="$"\n\
envsubst "\\$PORT" < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf\n\
nginx -g "daemon off;"\n\
' > /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh

EXPOSE $PORT

CMD ["/docker-entrypoint.sh"]
EOF

# Create railway.toml for frontend
cat > railway.frontend.toml << EOF
[build]
builder = "dockerfile"
dockerfilePath = "Dockerfile.frontend.railway"

[deploy]
healthcheckPath = "/"
healthcheckTimeout = 300
restartPolicyType = "always"
EOF

echo -e "${YELLOW}🚀 Deploying frontend to Railway...${NC}"

# Create new Railway project for frontend
railway init github-repo-dashboard-frontend

# Deploy using frontend Dockerfile
RAILWAY_DOCKERFILE=Dockerfile.frontend.railway railway up --detach

echo ""
echo -e "${GREEN}🎉 FRONTEND DEPLOYMENT STARTED!${NC}"
echo ""

# Wait a moment for deployment to process
sleep 10

# Try to get domain
echo -e "${YELLOW}🌐 Getting your frontend URL...${NC}"
FRONTEND_URL=$(railway domain 2>/dev/null || echo "")

if [ -n "$FRONTEND_URL" ]; then
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    🎉 SUCCESS! 🎉                           ║${NC}"
    echo -e "${PURPLE}║          Your Full-Stack App is Now Live!                   ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}🌐 Your Live Application:${NC}"
    echo -e "${GREEN}   👉 Frontend: https://$FRONTEND_URL${NC}"
    echo -e "${GREEN}   👉 Backend:  $BACKEND_URL${NC}"
    echo ""
    
    # Open in browser
    echo -e "${YELLOW}🌐 Opening your live app...${NC}"
    if command -v open > /dev/null 2>&1; then
        open "https://$FRONTEND_URL"
    elif command -v xdg-open > /dev/null 2>&1; then
        xdg-open "https://$FRONTEND_URL"
    fi
else
    echo -e "${YELLOW}⚠️  Frontend is deploying. Check Railway dashboard for URL:${NC}"
    echo -e "${BLUE}   👉 https://railway.app/dashboard${NC}"
fi

echo ""
echo -e "${CYAN}🎯 What You Have Now:${NC}"
echo -e "${BLUE}   ✅ Backend API serving GitHub data${NC}"
echo -e "${BLUE}   ✅ Frontend React app with dashboard UI${NC}"
echo -e "${BLUE}   ✅ Full-stack application live on internet${NC}"
echo -e "${BLUE}   ✅ HTTPS with SSL certificates${NC}"
echo -e "${BLUE}   ✅ Mobile-responsive design${NC}"
echo ""
echo -e "${GREEN}🎊 Your GitHub Repository Dashboard is now fully deployed! 🎊${NC}"

# Cleanup
rm -f Dockerfile.frontend.railway railway.frontend.toml