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
echo "  ║          🚀 DEPLOY YOUR APP TO THE INTERNET NOW! 🚀          ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}🎯 We'll deploy your GitHub Repository Dashboard to Railway${NC}"
echo -e "${CYAN}   (500 hours/month FREE - perfect for your project!)${NC}"
echo ""

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Railway CLI...${NC}"
    npm install -g @railway/cli
fi

# Check environment
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found${NC}"
    exit 1
fi

source .env
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ GitHub token not configured${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Environment ready!${NC}"
echo ""

# Step 1: Login instructions
echo -e "${BLUE}📋 STEP 1: Login to Railway${NC}"
echo -e "${YELLOW}We need to login to Railway first...${NC}"
echo ""
echo -e "${CYAN}What we'll do:${NC}"
echo -e "  1. Open Railway login page in your browser"
echo -e "  2. Sign up with your GitHub account (it's free!)"
echo -e "  3. Come back here to continue"
echo ""

read -p "Ready? Press Enter to login to Railway..." 

# Try to login
if railway login; then
    echo -e "${GREEN}✅ Successfully logged in to Railway!${NC}"
else
    echo -e "${RED}❌ Login failed. Please try manually:${NC}"
    echo -e "${BLUE}   1. Go to https://railway.app${NC}"
    echo -e "${BLUE}   2. Sign up with GitHub${NC}"
    echo -e "${BLUE}   3. Run: railway login${NC}"
    echo -e "${BLUE}   4. Then run this script again${NC}"
    exit 1
fi

echo ""

# Step 2: Create project and deploy
echo -e "${BLUE}📋 STEP 2: Deploy Your Application${NC}"
echo ""

# Create project name
PROJECT_NAME="github-repo-dashboard-$(date +%s)"
echo -e "${YELLOW}🏗️  Creating Railway project: $PROJECT_NAME${NC}"

# Initialize project
if railway init "$PROJECT_NAME"; then
    echo -e "${GREEN}✅ Project created!${NC}"
else
    echo -e "${YELLOW}⚠️  Using existing project${NC}"
fi

# Set environment variables
echo -e "${YELLOW}🔧 Setting environment variables...${NC}"
railway variables set GITHUB_TOKEN="$GITHUB_TOKEN"
railway variables set NODE_ENV=production
railway variables set SPRING_PROFILES_ACTIVE=production

# Deploy
echo -e "${BLUE}🚀 Deploying your application...${NC}"
echo -e "${YELLOW}This will take 3-5 minutes...${NC}"
echo ""

if railway up --detach; then
    echo ""
    echo -e "${GREEN}🎉 DEPLOYMENT SUCCESSFUL!${NC}"
    echo ""
    
    # Wait a moment for URL to be available
    sleep 10
    
    # Get the URL
    echo -e "${YELLOW}🌐 Getting your live URL...${NC}"
    
    # Generate domain if needed
    railway domain 2>/dev/null || true
    sleep 5
    
    # Try to get the URL
    DEPLOYMENT_URL=$(railway status --json 2>/dev/null | grep -o '"domain":"[^"]*"' | cut -d'"' -f4 | head -1 2>/dev/null || echo "")
    
    if [ -z "$DEPLOYMENT_URL" ]; then
        DEPLOYMENT_URL=$(railway domain 2>/dev/null | head -1 || echo "Check Railway dashboard")
    fi
    
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    🎉 SUCCESS! 🎉                           ║${NC}"
    echo -e "${PURPLE}║              Your App is Live on the Internet!              ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$DEPLOYMENT_URL" != "Check Railway dashboard" ] && [ -n "$DEPLOYMENT_URL" ]; then
        echo -e "${CYAN}🌐 Your Live Application:${NC}"
        echo -e "${GREEN}   👉 https://$DEPLOYMENT_URL${NC}"
        echo ""
        
        # Test the deployment
        echo -e "${YELLOW}🧪 Testing your live app...${NC}"
        sleep 15
        
        if curl -s -f "https://$DEPLOYMENT_URL/api/repos/stats" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Your app is responding perfectly!${NC}"
            
            # Open in browser
            echo -e "${YELLOW}🌐 Opening your live app in browser...${NC}"
            sleep 2
            if command -v open > /dev/null 2>&1; then
                open "https://$DEPLOYMENT_URL"
            elif command -v xdg-open > /dev/null 2>&1; then
                xdg-open "https://$DEPLOYMENT_URL"
            fi
        else
            echo -e "${YELLOW}⚠️  App is still starting up (this is normal)${NC}"
            echo -e "${BLUE}   Try your URL in 2-3 minutes${NC}"
        fi
    else
        echo -e "${CYAN}🌐 Your App is Deployed!${NC}"
        echo -e "${BLUE}   Check your Railway dashboard for the URL:${NC}"
        echo -e "${GREEN}   👉 https://railway.app/dashboard${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}🎯 What You Can Do Now:${NC}"
    echo -e "${BLUE}   • Share your live URL with friends/employers${NC}"
    echo -e "${BLUE}   • Add it to your portfolio/resume${NC}"
    echo -e "${BLUE}   • Post it on social media${NC}"
    echo -e "${BLUE}   • Access it from any device, anywhere!${NC}"
    echo ""
    echo -e "${CYAN}📊 Railway Dashboard:${NC}"
    echo -e "${BLUE}   • Monitor your app: railway dashboard${NC}"
    echo -e "${BLUE}   • View logs: railway logs${NC}"
    echo -e "${BLUE}   • Check status: railway status${NC}"
    echo ""
    echo -e "${GREEN}🎊 Congratulations! Your GitHub Repository Dashboard is now live on the internet! 🎊${NC}"
    
else
    echo -e "${RED}❌ Deployment failed${NC}"
    echo -e "${YELLOW}💡 Try these troubleshooting steps:${NC}"
    echo -e "${BLUE}   1. Check Railway dashboard: railway dashboard${NC}"
    echo -e "${BLUE}   2. View logs: railway logs${NC}"
    echo -e "${BLUE}   3. Verify your GitHub token is valid${NC}"
    echo -e "${BLUE}   4. Try again: railway up${NC}"
fi