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
    echo "  ║                  Railway Deployment                          ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_requirements() {
    echo -e "${YELLOW}🔍 Checking requirements...${NC}"
    
    # Check if Railway CLI is installed
    if ! command -v railway &> /dev/null; then
        echo -e "${RED}❌ Railway CLI is not installed.${NC}"
        echo -e "${BLUE}📦 Installing Railway CLI...${NC}"
        
        if command -v npm &> /dev/null; then
            npm install -g @railway/cli
        elif command -v brew &> /dev/null; then
            brew install railway
        else
            echo -e "${RED}❌ Please install Railway CLI manually:${NC}"
            echo -e "${BLUE}   npm install -g @railway/cli${NC}"
            echo -e "${BLUE}   OR visit: https://railway.app/cli${NC}"
            exit 1
        fi
    fi
    
    # Check if user is logged in
    if ! railway whoami &> /dev/null; then
        echo -e "${YELLOW}🔐 You need to login to Railway first${NC}"
        echo -e "${BLUE}Please run: railway login${NC}"
        echo ""
        read -p "Press Enter after you've logged in..."
        
        if ! railway whoami &> /dev/null; then
            echo -e "${RED}❌ Still not logged in. Please run 'railway login' first.${NC}"
            exit 1
        fi
    fi
    
    # Check GitHub token
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

create_railway_config() {
    echo -e "${YELLOW}📝 Creating Railway configuration...${NC}"
    
    # Create railway.json for better deployment configuration
    cat > railway.json << EOF
{
  "deploy": {
    "startCommand": "docker-compose up",
    "healthcheckPath": "/api/repos/stats",
    "healthcheckTimeout": 300
  }
}
EOF

    # Create Dockerfile for Railway (they prefer single Dockerfile)
    cat > Dockerfile.railway << 'EOF'
# Multi-stage build for Railway deployment
FROM maven:3.9.6-eclipse-temurin-21 AS backend-build
WORKDIR /app/backend
COPY backend/pom.xml .
RUN mvn dependency:go-offline -B
COPY backend/src ./src
RUN mvn clean package -DskipTests

FROM node:18-alpine AS frontend-build
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ .
RUN npm run build

# Production image
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

# Install nginx for serving frontend
RUN apt-get update && apt-get install -y nginx curl && rm -rf /var/lib/apt/lists/*

# Copy backend
COPY --from=backend-build /app/backend/target/*.jar app.jar

# Copy frontend build
COPY --from=frontend-build /app/frontend/build /var/www/html

# Copy nginx configuration
COPY frontend/nginx.conf /etc/nginx/sites-available/default

# Expose ports
EXPOSE 8080 3000

# Create startup script
RUN echo '#!/bin/bash\n\
nginx -g "daemon on;"\n\
java -jar app.jar\n\
' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
EOF

    echo -e "${GREEN}✅ Railway configuration created${NC}"
}

deploy_to_railway() {
    echo -e "${YELLOW}🚀 Deploying to Railway...${NC}"
    
    # Create new Railway project
    echo -e "${BLUE}📝 Project name (press Enter for 'github-repo-dashboard'):${NC}"
    read -p "Project name: " PROJECT_NAME
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME="github-repo-dashboard"
    fi
    
    # Initialize Railway project
    railway login
    
    # Check if project already exists
    if railway status &> /dev/null; then
        echo -e "${YELLOW}📂 Using existing Railway project${NC}"
    else
        echo -e "${BLUE}🆕 Creating new Railway project: $PROJECT_NAME${NC}"
        railway init "$PROJECT_NAME"
    fi
    
    # Set environment variables
    echo -e "${YELLOW}🔧 Setting environment variables...${NC}"
    railway variables set GITHUB_TOKEN="$GITHUB_TOKEN"
    railway variables set NODE_ENV=production
    railway variables set SPRING_PROFILES_ACTIVE=production
    railway variables set PORT=8080
    
    # Deploy using Docker
    echo -e "${BLUE}🐳 Deploying with Docker...${NC}"
    echo -e "${YELLOW}This may take 5-10 minutes...${NC}"
    
    # Railway will automatically detect and deploy the Docker setup
    railway up --detach
    
    # Wait for deployment
    echo -e "${YELLOW}⏳ Waiting for deployment to complete...${NC}"
    sleep 30
    
    # Get deployment URL
    DEPLOYMENT_URL=$(railway domain 2>/dev/null || echo "")
    
    if [ -z "$DEPLOYMENT_URL" ]; then
        echo -e "${YELLOW}🌐 Generating public URL...${NC}"
        railway domain
        sleep 5
        DEPLOYMENT_URL=$(railway domain 2>/dev/null || echo "")
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Deployment completed!${NC}"
    echo ""
    
    if [ -n "$DEPLOYMENT_URL" ]; then
        echo -e "${CYAN}🌐 Your application is available at:${NC}"
        echo -e "${BLUE}   👉 $DEPLOYMENT_URL${NC}"
        echo ""
        
        # Test the deployment
        echo -e "${YELLOW}🧪 Testing deployment...${NC}"
        sleep 10
        
        if curl -s -f "$DEPLOYMENT_URL/api/repos/stats" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Backend API is responding!${NC}"
        else
            echo -e "${YELLOW}⚠️  Backend may still be starting up. Check logs with: railway logs${NC}"
        fi
        
        # Open in browser
        read -p "Open application in browser? (Y/n): " OPEN_BROWSER
        if [[ ! $OPEN_BROWSER =~ ^[Nn]$ ]]; then
            if command -v open > /dev/null 2>&1; then
                open "$DEPLOYMENT_URL"
            elif command -v xdg-open > /dev/null 2>&1; then
                xdg-open "$DEPLOYMENT_URL"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  Could not retrieve deployment URL. Check Railway dashboard.${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}📊 Useful Railway commands:${NC}"
    echo -e "${BLUE}   railway logs        ${NC}# View deployment logs"
    echo -e "${BLUE}   railway status      ${NC}# Check deployment status"
    echo -e "${BLUE}   railway domain      ${NC}# Get deployment URL"
    echo -e "${BLUE}   railway variables   ${NC}# Manage environment variables"
    echo -e "${BLUE}   railway dashboard   ${NC}# Open Railway dashboard"
}

setup_custom_domain() {
    echo -e "${YELLOW}🌐 Setting up custom domain (optional)...${NC}"
    echo ""
    echo -e "${BLUE}Do you have a custom domain you'd like to use? (y/N):${NC}"
    read -p "Custom domain: " USE_CUSTOM_DOMAIN
    
    if [[ $USE_CUSTOM_DOMAIN =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Enter your domain (e.g., myapp.com):${NC}"
        read -p "Domain: " CUSTOM_DOMAIN
        
        if [ -n "$CUSTOM_DOMAIN" ]; then
            echo -e "${YELLOW}🔧 Adding custom domain to Railway...${NC}"
            
            # Add domain to Railway
            railway domain add "$CUSTOM_DOMAIN"
            
            echo -e "${GREEN}✅ Custom domain added!${NC}"
            echo ""
            echo -e "${YELLOW}📝 DNS Configuration Required:${NC}"
            echo -e "${BLUE}Add the following CNAME record to your DNS:${NC}"
            echo -e "${BLUE}   Name: @ (or www)${NC}"
            echo -e "${BLUE}   Value: [Railway will provide this]${NC}"
            echo ""
            echo -e "${BLUE}Check Railway dashboard for exact DNS settings:${NC}"
            railway dashboard
        fi
    fi
}

cleanup_deployment_files() {
    echo -e "${YELLOW}🧹 Cleaning up temporary files...${NC}"
    rm -f railway.json Dockerfile.railway
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

show_post_deployment_info() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    Deployment Complete!                     ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}🎉 Your GitHub Repository Dashboard is now live on the internet!${NC}"
    echo ""
    echo -e "${YELLOW}📋 What happens next:${NC}"
    echo -e "${BLUE}   1. Railway will automatically deploy updates when you push to GitHub${NC}"
    echo -e "${BLUE}   2. Your app will auto-scale based on traffic${NC}"
    echo -e "${BLUE}   3. Railway provides 500 hours/month free (enough for small projects)${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Managing your deployment:${NC}"
    echo -e "${BLUE}   • View logs: railway logs${NC}"
    echo -e "${BLUE}   • Check status: railway status${NC}"
    echo -e "${BLUE}   • Dashboard: railway dashboard${NC}"
    echo -e "${BLUE}   • Redeploy: railway up${NC}"
    echo ""
    echo -e "${YELLOW}💡 Pro Tips:${NC}"
    echo -e "${BLUE}   • Connect your GitHub repo for auto-deployments${NC}"
    echo -e "${BLUE}   • Set up monitoring in Railway dashboard${NC}"
    echo -e "${BLUE}   • Consider upgrading for production workloads${NC}"
    echo ""
    echo -e "${GREEN}✨ Happy coding! Your app is now accessible worldwide! ✨${NC}"
}

main() {
    show_banner
    
    check_requirements
    create_railway_config
    deploy_to_railway
    setup_custom_domain
    cleanup_deployment_files
    show_post_deployment_info
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}⚠️  Deployment interrupted. You can resume by running this script again.${NC}"; exit 1' INT

# Run main function
main "$@"