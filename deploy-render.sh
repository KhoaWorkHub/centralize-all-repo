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

show_banner() {
    echo -e "${PURPLE}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║              GitHub Repository Dashboard                     ║"
    echo "  ║                   Render Deployment                          ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_requirements() {
    echo -e "${YELLOW}🔍 Checking requirements...${NC}"
    
    # Check if git is initialized
    if [ ! -d .git ]; then
        echo -e "${RED}❌ Git repository not initialized. Please run:${NC}"
        echo -e "${BLUE}   git init${NC}"
        echo -e "${BLUE}   git add .${NC}"
        echo -e "${BLUE}   git commit -m 'Initial commit'${NC}"
        exit 1
    fi
    
    # Check if GitHub token is configured
    if [ ! -f .env ]; then
        echo -e "${RED}❌ .env file not found. Please run ./services.sh start first to set up your environment.${NC}"
        exit 1
    fi
    
    source .env
    if [ -z "$GITHUB_TOKEN" ] || [ "$GITHUB_TOKEN" = "your_github_personal_access_token_here" ]; then
        echo -e "${RED}❌ GitHub token not configured in .env file${NC}"
        echo -e "${YELLOW}Please set your GitHub Personal Access Token in .env file${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All requirements satisfied${NC}"
    echo ""
}

create_render_config() {
    echo -e "${YELLOW}📝 Creating Render configuration files...${NC}"
    
    # Create render.yaml for Infrastructure as Code
    cat > render.yaml << EOF
services:
  - type: web
    name: github-repo-dashboard
    env: docker
    dockerfilePath: ./Dockerfile.render
    repo: https://github.com/\${GITHUB_USERNAME}/github-repo-dashboard.git
    branch: main
    envVars:
      - key: GITHUB_TOKEN
        sync: false
      - key: NODE_ENV
        value: production
      - key: SPRING_PROFILES_ACTIVE
        value: production
      - key: PORT
        value: "8080"
    buildCommand: docker build -f Dockerfile.render -t github-repo-dashboard .
    startCommand: java -jar app.jar
    healthCheckPath: /api/repos/stats
    autoDeploy: true
    scaling:
      minInstances: 1
      maxInstances: 1
EOF

    # Create optimized Dockerfile for Render
    cat > Dockerfile.render << 'EOF'
# Multi-stage build optimized for Render
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

# Copy nginx configuration
COPY frontend/nginx.conf /etc/nginx/sites-available/default

# Create startup script that runs both nginx and Spring Boot
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Start nginx in background\n\
nginx -g "daemon off;" &\n\
NGINX_PID=$!\n\
\n\
# Start Spring Boot application\n\
java -Dserver.port=${PORT:-8080} -jar app.jar &\n\
JAVA_PID=$!\n\
\n\
# Function to handle shutdown\n\
shutdown() {\n\
    echo "Shutting down..."\n\
    kill $NGINX_PID $JAVA_PID\n\
    wait $NGINX_PID $JAVA_PID\n\
    exit 0\n\
}\n\
\n\
# Trap signals\n\
trap shutdown SIGTERM SIGINT\n\
\n\
# Wait for both processes\n\
wait $NGINX_PID $JAVA_PID\n\
' > /app/start.sh && chmod +x /app/start.sh

EXPOSE ${PORT:-8080}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8080}/api/repos/stats || exit 1

CMD ["/app/start.sh"]
EOF

    # Create .dockerignore for better build performance
    cat > .dockerignore << EOF
node_modules
npm-debug.log
target/
.git
.gitignore
README.md
docs/
*.md
.env
.env.*
logs/
coverage/
.nyc_output
.cache
.DS_Store
Thumbs.db
EOF

    echo -e "${GREEN}✅ Render configuration files created${NC}"
}

push_to_github() {
    echo -e "${YELLOW}📤 Preparing GitHub repository...${NC}"
    
    # Check if we need to create a GitHub repository
    if ! git remote get-url origin &> /dev/null; then
        echo -e "${BLUE}🐙 GitHub repository not configured.${NC}"
        echo -e "${BLUE}Please run ./setup-github.sh first, or manually set up your GitHub repo.${NC}"
        
        read -p "Do you want to run the GitHub setup now? (Y/n): " SETUP_GITHUB
        if [[ ! $SETUP_GITHUB =~ ^[Nn]$ ]]; then
            ./setup-github.sh
        else
            echo -e "${YELLOW}⚠️  Manual GitHub setup required:${NC}"
            echo -e "${BLUE}   1. Create a GitHub repository${NC}"
            echo -e "${BLUE}   2. git remote add origin <your-repo-url>${NC}"
            echo -e "${BLUE}   3. git push -u origin main${NC}"
            exit 1
        fi
    fi
    
    # Add new files and commit
    echo -e "${YELLOW}📝 Committing Render configuration...${NC}"
    git add render.yaml Dockerfile.render .dockerignore
    
    if git diff --staged --quiet; then
        echo -e "${BLUE}ℹ️  No new changes to commit${NC}"
    else
        git commit -m "Add Render deployment configuration

- Add render.yaml for Infrastructure as Code
- Add optimized Dockerfile for Render deployment
- Add .dockerignore for better build performance

🚀 Ready for Render deployment"
    fi
    
    # Push to GitHub
    echo -e "${YELLOW}📤 Pushing to GitHub...${NC}"
    git push origin main
    
    echo -e "${GREEN}✅ Code pushed to GitHub${NC}"
}

setup_render_deployment() {
    echo -e "${YELLOW}🚀 Setting up Render deployment...${NC}"
    echo ""
    
    # Get GitHub repository URL
    GITHUB_URL=$(git remote get-url origin)
    GITHUB_REPO=$(echo "$GITHUB_URL" | sed -E 's/.*github\.com[:/](.+)\.git$/\1/')
    
    echo -e "${CYAN}📋 Render Deployment Steps:${NC}"
    echo ""
    echo -e "${BLUE}1. 🌐 Go to https://render.com and sign up/login${NC}"
    echo -e "${BLUE}2. 📤 Connect your GitHub account${NC}"
    echo -e "${BLUE}3. ➕ Click 'New +' > 'Web Service'${NC}"
    echo -e "${BLUE}4. 🔗 Connect your repository: $GITHUB_REPO${NC}"
    echo -e "${BLUE}5. ⚙️  Use these settings:${NC}"
    echo ""
    echo -e "${YELLOW}   Configuration:${NC}"
    echo -e "${GREEN}   • Name: github-repo-dashboard${NC}"
    echo -e "${GREEN}   • Environment: Docker${NC}"
    echo -e "${GREEN}   • Region: Choose closest to you${NC}"
    echo -e "${GREEN}   • Branch: main${NC}"
    echo -e "${GREEN}   • Dockerfile Path: ./Dockerfile.render${NC}"
    echo ""
    echo -e "${YELLOW}   Environment Variables:${NC}"
    echo -e "${GREEN}   • GITHUB_TOKEN = $GITHUB_TOKEN${NC}"
    echo -e "${GREEN}   • NODE_ENV = production${NC}"
    echo -e "${GREEN}   • SPRING_PROFILES_ACTIVE = production${NC}"
    echo ""
    echo -e "${BLUE}6. 🚀 Click 'Create Web Service'${NC}"
    echo ""
    
    echo -e "${YELLOW}⏳ Deployment will take 5-10 minutes...${NC}"
    echo ""
    
    read -p "Press Enter when you've started the deployment on Render..."
    
    echo -e "${BLUE}🌐 Open Render dashboard to monitor deployment:${NC}"
    if command -v open > /dev/null 2>&1; then
        open "https://dashboard.render.com"
    elif command -v xdg-open > /dev/null 2>&1; then
        xdg-open "https://dashboard.render.com"
    else
        echo -e "${BLUE}   👉 https://dashboard.render.com${NC}"
    fi
}

create_render_blueprint() {
    echo -e "${YELLOW}📋 Creating Render Blueprint (Advanced)...${NC}"
    
    # Create a comprehensive render blueprint
    cat > render-blueprint.yaml << EOF
# Render Blueprint for GitHub Repository Dashboard
# This file can be used for one-click deployment

services:
  - type: web
    name: github-repo-dashboard
    env: docker
    dockerfilePath: ./Dockerfile.render
    buildCommand: docker build -f Dockerfile.render -t github-repo-dashboard .
    healthCheckPath: /api/repos/stats
    envVars:
      - key: GITHUB_TOKEN
        generateValue: false  # User must provide this
      - key: NODE_ENV
        value: production
      - key: SPRING_PROFILES_ACTIVE
        value: production
    scaling:
      minInstances: 1
      maxInstances: 3
    autoDeploy: true
    
# Optional: Add PostgreSQL database for production
# databases:
#   - name: github-repo-dashboard-db
#     databaseName: github_repo_dashboard
#     user: dashboard_user
EOF

    echo -e "${GREEN}✅ Render Blueprint created (render-blueprint.yaml)${NC}"
}

show_deployment_info() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                  Render Deployment Guide                    ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}🎉 Your GitHub Repository Dashboard is ready for Render deployment!${NC}"
    echo ""
    echo -e "${YELLOW}📋 What you get with Render:${NC}"
    echo -e "${BLUE}   ✅ Free tier: 750 hours/month${NC}"
    echo -e "${BLUE}   ✅ Automatic HTTPS/SSL${NC}"
    echo -e "${BLUE}   ✅ Global CDN${NC}"
    echo -e "${BLUE}   ✅ Auto-deploy from GitHub${NC}"
    echo -e "${BLUE}   ✅ Zero-downtime deployments${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Render Dashboard Features:${NC}"
    echo -e "${BLUE}   • Real-time deployment logs${NC}"
    echo -e "${BLUE}   • Environment variable management${NC}"
    echo -e "${BLUE}   • Custom domain setup${NC}"
    echo -e "${BLUE}   • Scaling controls${NC}"
    echo -e "${BLUE}   • Health monitoring${NC}"
    echo ""
    echo -e "${YELLOW}💡 Pro Tips:${NC}"
    echo -e "${BLUE}   • Enable auto-deploy for seamless updates${NC}"
    echo -e "${BLUE}   • Set up health checks in Render dashboard${NC}"
    echo -e "${BLUE}   • Consider upgrading to Pro for production use${NC}"
    echo -e "${BLUE}   • Use PostgreSQL add-on for production database${NC}"
    echo ""
    echo -e "${YELLOW}🆘 Troubleshooting:${NC}"
    echo -e "${BLUE}   • Check deployment logs in Render dashboard${NC}"
    echo -e "${BLUE}   • Verify environment variables are set${NC}"
    echo -e "${BLUE}   • Ensure GitHub token has proper permissions${NC}"
    echo ""
    echo -e "${GREEN}✨ Your app will be live at: https://your-app-name.onrender.com ✨${NC}"
}

cleanup_deployment_files() {
    echo -e "${YELLOW}🧹 Cleaning up temporary files...${NC}"
    # Keep the important files, only remove temporary ones
    echo -e "${BLUE}ℹ️  Keeping deployment files for future use${NC}"
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

main() {
    show_banner
    
    check_requirements
    create_render_config
    create_render_blueprint
    push_to_github
    setup_render_deployment
    show_deployment_info
    
    echo ""
    echo -e "${GREEN}🎉 Render deployment setup complete!${NC}"
    echo -e "${BLUE}Monitor your deployment at: https://dashboard.render.com${NC}"
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}⚠️  Setup interrupted. You can resume by running this script again.${NC}"; exit 1' INT

# Run main function
main "$@"