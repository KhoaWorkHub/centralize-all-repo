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
    echo "  ║                 Universal Deployment                         ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_deployment_options() {
    echo -e "${CYAN}🚀 Choose your deployment platform:${NC}"
    echo ""
    echo -e "${GREEN}1. Railway${NC} (Recommended for beginners)"
    echo -e "   ✅ 500 hours/month free"
    echo -e "   ✅ Auto-deploy from GitHub"
    echo -e "   ✅ Easiest setup"
    echo -e "   ✅ Built-in monitoring"
    echo ""
    echo -e "${GREEN}2. Render${NC} (Great for production)"
    echo -e "   ✅ 750 hours/month free"
    echo -e "   ✅ Automatic HTTPS/SSL"
    echo -e "   ✅ Global CDN"
    echo -e "   ✅ Zero-downtime deployments"
    echo ""
    echo -e "${GREEN}3. Fly.io${NC} (Global edge deployment)"
    echo -e "   ✅ $5 credit monthly"
    echo -e "   ✅ Global regions"
    echo -e "   ✅ Auto-scaling"
    echo -e "   ✅ Edge computing"
    echo ""
    echo -e "${GREEN}4. Google Cloud Run${NC} (Serverless)"
    echo -e "   ✅ 2M requests/month free"
    echo -e "   ✅ Scale to zero"
    echo -e "   ✅ Pay per use"
    echo -e "   ✅ Google Cloud integration"
    echo ""
    echo -e "${GREEN}5. Manual VPS${NC} (Full control)"
    echo -e "   ⚠️  $5-10/month"
    echo -e "   ✅ Full control"
    echo -e "   ✅ Custom configuration"
    echo -e "   ✅ SSH access"
    echo ""
    echo -e "${BLUE}0. Setup local development only${NC}"
    echo ""
}

deploy_railway() {
    echo -e "${YELLOW}🚀 Deploying to Railway...${NC}"
    if [ -f "./deploy-railway.sh" ]; then
        ./deploy-railway.sh
    else
        echo -e "${RED}❌ Railway deployment script not found${NC}"
        exit 1
    fi
}

deploy_render() {
    echo -e "${YELLOW}🚀 Deploying to Render...${NC}"
    if [ -f "./deploy-render.sh" ]; then
        ./deploy-render.sh
    else
        echo -e "${RED}❌ Render deployment script not found${NC}"
        exit 1
    fi
}

deploy_fly() {
    echo -e "${YELLOW}🚀 Deploying to Fly.io...${NC}"
    
    # Check if flyctl is installed
    if ! command -v fly &> /dev/null; then
        echo -e "${BLUE}📦 Installing Fly CLI...${NC}"
        curl -L https://fly.io/install.sh | sh
        export PATH="$HOME/.fly/bin:$PATH"
    fi
    
    # Check if user is logged in
    if ! fly auth whoami &> /dev/null; then
        echo -e "${YELLOW}🔐 Please login to Fly.io:${NC}"
        fly auth login
    fi
    
    # Create fly.toml configuration
    cat > fly.toml << EOF
app = "github-repo-dashboard"
primary_region = "dfw"

[env]
  NODE_ENV = "production"
  SPRING_PROFILES_ACTIVE = "production"
  PORT = "8080"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true

[checks]
  [checks.health]
    grace_period = "30s"
    interval = "15s"
    method = "GET"
    path = "/api/repos/stats"
    port = 8080
    timeout = "10s"
    type = "http"

[[vm]]
  cpu_kind = "shared"
  cpus = 1
  memory_mb = 512
EOF

    # Create Dockerfile for Fly
    cat > Dockerfile.fly << 'EOF'
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
RUN npm ci
COPY frontend/ .
RUN npm run build

FROM eclipse-temurin:21-jre-jammy
RUN apt-get update && apt-get install -y nginx curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=backend-build /app/backend/target/*.jar app.jar
COPY --from=frontend-build /app/frontend/build /var/www/html
COPY frontend/nginx.conf /etc/nginx/sites-available/default

RUN echo '#!/bin/bash\nnginx -g "daemon off;" &\njava -Dserver.port=${PORT:-8080} -jar app.jar\n' > start.sh && chmod +x start.sh

EXPOSE ${PORT:-8080}
CMD ["./start.sh"]
EOF

    # Deploy to Fly
    source .env
    fly secrets set GITHUB_TOKEN="$GITHUB_TOKEN"
    fly launch --dockerfile Dockerfile.fly --no-deploy
    fly deploy
    
    # Get app URL
    APP_URL=$(fly status --json | grep -o '"hostname":"[^"]*"' | cut -d'"' -f4 | head -1)
    
    echo -e "${GREEN}✅ Deployed to Fly.io!${NC}"
    echo -e "${BLUE}🌐 Your app: https://$APP_URL${NC}"
    
    # Cleanup
    rm -f fly.toml Dockerfile.fly
}

deploy_gcp_run() {
    echo -e "${YELLOW}🚀 Deploying to Google Cloud Run...${NC}"
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}❌ Google Cloud SDK not installed${NC}"
        echo -e "${BLUE}Please install it from: https://cloud.google.com/sdk/docs/install${NC}"
        exit 1
    fi
    
    # Check if user is logged in
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 &> /dev/null; then
        echo -e "${YELLOW}🔐 Please login to Google Cloud:${NC}"
        gcloud auth login
    fi
    
    # Set project
    echo -e "${BLUE}Enter your Google Cloud Project ID:${NC}"
    read -p "Project ID: " PROJECT_ID
    gcloud config set project "$PROJECT_ID"
    
    # Enable required APIs
    gcloud services enable cloudbuild.googleapis.com run.googleapis.com
    
    # Build and deploy
    source .env
    
    gcloud run deploy github-repo-dashboard \
        --source . \
        --platform managed \
        --region us-central1 \
        --allow-unauthenticated \
        --set-env-vars "GITHUB_TOKEN=$GITHUB_TOKEN,NODE_ENV=production,SPRING_PROFILES_ACTIVE=production"
    
    echo -e "${GREEN}✅ Deployed to Google Cloud Run!${NC}"
}

setup_vps() {
    echo -e "${YELLOW}🖥️  VPS Deployment Guide${NC}"
    echo ""
    echo -e "${CYAN}📋 VPS Setup Instructions:${NC}"
    echo ""
    echo -e "${BLUE}1. Get a VPS (recommended providers):${NC}"
    echo -e "   • DigitalOcean ($5/month) - https://digitalocean.com"
    echo -e "   • Linode ($5/month) - https://linode.com"
    echo -e "   • Vultr ($5/month) - https://vultr.com"
    echo ""
    echo -e "${BLUE}2. SSH into your VPS:${NC}"
    echo -e "   ssh root@your-server-ip"
    echo ""
    echo -e "${BLUE}3. Install Docker:${NC}"
    echo -e "   curl -fsSL https://get.docker.com -o get-docker.sh"
    echo -e "   sh get-docker.sh"
    echo ""
    echo -e "${BLUE}4. Install Docker Compose:${NC}"
    echo -e "   sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
    echo -e "   sudo chmod +x /usr/local/bin/docker-compose"
    echo ""
    echo -e "${BLUE}5. Clone your repository:${NC}"
    echo -e "   git clone https://github.com/YOUR_USERNAME/github-repo-dashboard.git"
    echo -e "   cd github-repo-dashboard"
    echo ""
    echo -e "${BLUE}6. Set up environment:${NC}"
    echo -e "   echo \"GITHUB_TOKEN=your_token_here\" > .env"
    echo ""
    echo -e "${BLUE}7. Start the application:${NC}"
    echo -e "   ./start.sh"
    echo ""
    echo -e "${BLUE}8. Set up reverse proxy with SSL (optional):${NC}"
    echo -e "   # Install Nginx"
    echo -e "   sudo apt update && sudo apt install nginx certbot python3-certbot-nginx"
    echo -e "   "
    echo -e "   # Configure Nginx (create /etc/nginx/sites-available/github-dashboard)"
    echo -e "   # Get SSL certificate"
    echo -e "   sudo certbot --nginx -d yourdomain.com"
    echo ""
    echo -e "${GREEN}✅ Your app will be available at your server IP or domain!${NC}"
}

setup_local_dev() {
    echo -e "${YELLOW}💻 Setting up local development...${NC}"
    
    # Check requirements
    if [ ! -f .env ]; then
        echo -e "${YELLOW}⚠️  .env file not found. Creating from template...${NC}"
        if [ -f .env.example ]; then
            cp .env.example .env
        else
            echo "GITHUB_TOKEN=your_github_personal_access_token_here" > .env
        fi
        echo -e "${YELLOW}📝 Please edit .env file and add your GitHub Personal Access Token${NC}"
        echo -e "${YELLOW}   Get one from: https://github.com/settings/tokens${NC}"
        exit 1
    fi
    
    # Start local development
    ./services.sh start
    
    echo -e "${GREEN}✅ Local development environment is ready!${NC}"
    echo -e "${BLUE}🌐 Frontend: http://localhost:3000${NC}"
    echo -e "${BLUE}🔧 Backend: http://localhost:8080${NC}"
}

main() {
    show_banner
    
    # Check if GitHub token is configured
    if [ ! -f .env ]; then
        echo -e "${YELLOW}⚠️  Environment not configured. Setting up...${NC}"
        if [ -f .env.example ]; then
            cp .env.example .env
        else
            echo "GITHUB_TOKEN=your_github_personal_access_token_here" > .env
        fi
        echo -e "${RED}❌ Please edit .env file and add your GitHub Personal Access Token${NC}"
        echo -e "${YELLOW}   Get one from: https://github.com/settings/tokens${NC}"
        echo -e "${YELLOW}   Then run this script again.${NC}"
        exit 1
    fi
    
    source .env
    if [ -z "$GITHUB_TOKEN" ] || [ "$GITHUB_TOKEN" = "your_github_personal_access_token_here" ]; then
        echo -e "${RED}❌ GitHub token not configured in .env file${NC}"
        echo -e "${YELLOW}Please set your GitHub Personal Access Token in .env file${NC}"
        exit 1
    fi
    
    show_deployment_options
    
    echo -e "${CYAN}Select deployment option (1-5, or 0 for local dev):${NC}"
    read -p "Choice: " CHOICE
    
    case $CHOICE in
        1)
            deploy_railway
            ;;
        2)
            deploy_render
            ;;
        3)
            deploy_fly
            ;;
        4)
            deploy_gcp_run
            ;;
        5)
            setup_vps
            ;;
        0)
            setup_local_dev
            ;;
        *)
            echo -e "${RED}❌ Invalid choice. Please select 0-5.${NC}"
            exit 1
            ;;
    esac
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}⚠️  Deployment interrupted. You can resume by running this script again.${NC}"; exit 1' INT

# Run main function
main "$@"