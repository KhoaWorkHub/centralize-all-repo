#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 GitHub Repository Dashboard - One-Click Startup${NC}"
echo -e "${BLUE}=================================================${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose > /dev/null 2>&1 && ! command -v docker > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker Compose is not available. Please install Docker Compose.${NC}"
    exit 1
fi

# Check for .env file and GitHub token
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Copying from .env.example...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}📝 Please edit .env file and add your GitHub Personal Access Token${NC}"
    echo -e "${YELLOW}   You can get one from: https://github.com/settings/tokens${NC}"
    echo -e "${YELLOW}   Required permissions: repo (read access)${NC}"
    echo ""
    
    # Check if GITHUB_TOKEN is set as environment variable
    if [ -z "$GITHUB_TOKEN" ]; then
        echo -e "${RED}❌ GitHub token not configured. Please:${NC}"
        echo -e "${RED}   1. Edit .env file and set GITHUB_TOKEN, OR${NC}"
        echo -e "${RED}   2. Export GITHUB_TOKEN environment variable${NC}"
        echo ""
        echo -e "${YELLOW}Example: export GITHUB_TOKEN=your_token_here${NC}"
        echo -e "${YELLOW}Then run: ./start.sh${NC}"
        exit 1
    fi
fi

# Load environment variables from .env file
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Final check for GitHub token
if [ -z "$GITHUB_TOKEN" ] || [ "$GITHUB_TOKEN" = "your_github_personal_access_token_here" ]; then
    echo -e "${RED}❌ GitHub token not properly configured.${NC}"
    echo -e "${RED}   Please set a valid GitHub Personal Access Token in .env file or as environment variable.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is running${NC}"
echo -e "${GREEN}✅ GitHub token is configured${NC}"
echo ""

# Stop any existing containers
echo -e "${YELLOW}🛑 Stopping any existing containers...${NC}"
if command -v docker-compose > /dev/null 2>&1; then
    docker-compose down --remove-orphans 2>/dev/null || true
elif docker compose version > /dev/null 2>&1; then
    docker compose down --remove-orphans 2>/dev/null || true
fi

# Build and start the application
echo -e "${YELLOW}🔨 Building and starting the application...${NC}"
echo -e "${YELLOW}   This may take a few minutes on first run...${NC}"
echo ""

# Use docker compose (new format) or docker-compose (legacy) based on availability
if docker compose version > /dev/null 2>&1; then
    echo -e "${YELLOW}📦 Using 'docker compose' (new format)...${NC}"
    docker compose up --build -d
elif command -v docker-compose > /dev/null 2>&1; then
    echo -e "${YELLOW}📦 Using 'docker-compose' (legacy format)...${NC}"
    docker-compose up --build -d
else
    echo -e "${RED}❌ Error: Neither 'docker compose' nor 'docker-compose' command found.${NC}"
    echo -e "${RED}   Please install Docker Compose or update your Docker installation.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Application is starting up!${NC}"
echo ""
echo -e "${BLUE}📊 Services:${NC}"
echo -e "${BLUE}   • Frontend: http://localhost:3000${NC}"
echo -e "${BLUE}   • Backend API: http://localhost:8080${NC}"
echo -e "${BLUE}   • API Documentation: http://localhost:8080/api/repos${NC}"
echo ""

# Wait for services to be healthy
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"

# Function to check if a service is healthy
check_health() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name is ready!${NC}"
            return 0
        fi
        echo -e "${YELLOW}   Attempt $attempt/$max_attempts - Waiting for $service_name...${NC}"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ $service_name failed to start within expected time${NC}"
    return 1
}

# Check backend health
if check_health "Backend" "http://localhost:8080/api/repos/stats"; then
    # Check frontend health
    if check_health "Frontend" "http://localhost:3000"; then
        echo ""
        echo -e "${GREEN}🎉 SUCCESS! GitHub Repository Dashboard is now running!${NC}"
        echo ""
        echo -e "${BLUE}🌐 Open your browser and visit:${NC}"
        echo -e "${BLUE}   👉 http://localhost:3000${NC}"
        echo ""
        echo -e "${BLUE}📝 To stop the application:${NC}"
        echo -e "${BLUE}   docker-compose down${NC}"
        echo ""
        echo -e "${BLUE}📊 To view logs:${NC}"
        echo -e "${BLUE}   docker-compose logs -f${NC}"
        echo ""
        
        # Automatically open browser on macOS and Linux with GUI
        if command -v open > /dev/null 2>&1; then
            echo -e "${YELLOW}🌐 Opening browser...${NC}"
            sleep 2
            open http://localhost:3000
        elif command -v xdg-open > /dev/null 2>&1; then
            echo -e "${YELLOW}🌐 Opening browser...${NC}"
            sleep 2
            xdg-open http://localhost:3000
        fi
        
    else
        echo -e "${RED}❌ Frontend failed to start. Check logs with: docker-compose logs frontend${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Backend failed to start. Check logs with: docker-compose logs backend${NC}"
    echo -e "${YELLOW}💡 Common issues:${NC}"
    echo -e "${YELLOW}   • Invalid GitHub token${NC}"
    echo -e "${YELLOW}   • Network connectivity issues${NC}"
    echo -e "${YELLOW}   • Port 8080 already in use${NC}"
    exit 1
fi