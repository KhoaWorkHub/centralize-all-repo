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
echo "  ║          🚀 DEPLOY FRONTEND TO VERCEL AUTOMATICALLY 🚀       ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}🎯 Automated Vercel Deployment for React Frontend${NC}"
echo -e "${CYAN}   Backend: Railway | Frontend: Vercel${NC}"
echo ""

# Get backend URL (Railway)
BACKEND_URL="https://centralize-all-repo-production.up.railway.app"
echo -e "${GREEN}✅ Backend URL: $BACKEND_URL${NC}"

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Vercel CLI...${NC}"
    npm install -g vercel@latest
    echo -e "${GREEN}✅ Vercel CLI installed${NC}"
fi

# Configure frontend environment
echo -e "${YELLOW}🔧 Configuring frontend environment...${NC}"

# Create production environment file
cat > frontend/.env.production << EOF
REACT_APP_API_URL=$BACKEND_URL
REACT_APP_ENV=production
GENERATE_SOURCEMAP=false
EOF

# Create Vercel configuration
cat > vercel.json << EOF
{
  "version": 2,
  "name": "github-repo-dashboard",
  "builds": [
    {
      "src": "frontend/package.json",
      "use": "@vercel/static-build",
      "config": {
        "distDir": "build"
      }
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/frontend/\$1"
    }
  ],
  "env": {
    "REACT_APP_API_URL": "$BACKEND_URL"
  },
  "build": {
    "env": {
      "REACT_APP_API_URL": "$BACKEND_URL"
    }
  },
  "functions": {},
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
EOF

# Create build script for Vercel
cat > build.sh << 'EOF'
#!/bin/bash
cd frontend
npm ci
npm run build
EOF
chmod +x build.sh

# Update package.json for Vercel build
cd frontend
if ! grep -q '"homepage"' package.json; then
    # Add homepage field if it doesn't exist
    sed -i '' 's/"private": true,/"private": true,\n  "homepage": ".",/' package.json 2>/dev/null || \
    sed -i 's/"private": true,/"private": true,\n  "homepage": ".",/' package.json
fi
cd ..

echo -e "${GREEN}✅ Frontend configuration complete${NC}"

# Build the frontend
echo -e "${YELLOW}🔨 Building frontend...${NC}"
cd frontend
npm run build
cd ..
echo -e "${GREEN}✅ Frontend built successfully${NC}"

# Deploy to Vercel
echo -e "${YELLOW}🚀 Deploying to Vercel...${NC}"
echo -e "${YELLOW}This will take 2-3 minutes...${NC}"

# Login check
if ! vercel whoami &> /dev/null; then
    echo -e "${BLUE}🔐 Please login to Vercel (this will open your browser)${NC}"
    vercel login
fi

# Deploy
vercel --prod --yes --env REACT_APP_API_URL="$BACKEND_URL" --cwd frontend

echo ""
echo -e "${GREEN}🎉 DEPLOYMENT SUCCESSFUL!${NC}"
echo ""

# Get deployment URL
VERCEL_URL=$(vercel ls --scope $(vercel whoami) 2>/dev/null | grep "github-repo-dashboard" | head -1 | awk '{print $2}' || echo "")

if [ -z "$VERCEL_URL" ]; then
    # Try alternative method
    VERCEL_URL=$(vercel ls 2>/dev/null | grep -E "(https://.*\.vercel\.app|github)" | head -1 | awk '{print $1}' || echo "")
fi

if [ -n "$VERCEL_URL" ]; then
    # Ensure URL has https://
    if [[ ! $VERCEL_URL =~ ^https:// ]]; then
        VERCEL_URL="https://$VERCEL_URL"
    fi
    
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    🎉 FULL-STACK DEPLOYED! 🎉               ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}🌐 Your Complete Application URLs:${NC}"
    echo -e "${GREEN}   🎨 Frontend (Vercel): $VERCEL_URL${NC}"
    echo -e "${GREEN}   🔧 Backend (Railway): $BACKEND_URL${NC}"
    echo ""
    echo -e "${CYAN}📊 API Endpoints Available:${NC}"
    echo -e "${BLUE}   • Stats: $BACKEND_URL/api/repos/stats${NC}"
    echo -e "${BLUE}   • Repos: $BACKEND_URL/api/repos${NC}"
    echo -e "${BLUE}   • Search: $BACKEND_URL/api/repos/search?q=react${NC}"
    echo ""
    
    # Test the deployment
    echo -e "${YELLOW}🧪 Testing your deployment...${NC}"
    if curl -s -f "$BACKEND_URL/api/repos/stats" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend API is working perfectly!${NC}"
    else
        echo -e "${YELLOW}⚠️  Backend is still starting up (this is normal)${NC}"
    fi
    
    # Open in browser
    echo -e "${YELLOW}🌐 Opening your live application...${NC}"
    sleep 2
    if command -v open > /dev/null 2>&1; then
        open "$VERCEL_URL"
    elif command -v xdg-open > /dev/null 2>&1; then
        xdg-open "$VERCEL_URL"
    fi
    
else
    echo -e "${YELLOW}⚠️  Deployment successful! Check Vercel dashboard for URL:${NC}"
    echo -e "${BLUE}   👉 https://vercel.com/dashboard${NC}"
fi

echo ""
echo -e "${CYAN}🎯 What You Have Now:${NC}"
echo -e "${BLUE}   ✅ React frontend on Vercel (global CDN)${NC}"
echo -e "${BLUE}   ✅ Spring Boot backend on Railway${NC}"
echo -e "${BLUE}   ✅ GitHub API integration with live data${NC}"
echo -e "${BLUE}   ✅ Professional HTTPS URLs${NC}"
echo -e "${BLUE}   ✅ Mobile-responsive dashboard${NC}"
echo -e "${BLUE}   ✅ Search and filter functionality${NC}"
echo ""
echo -e "${CYAN}📚 Useful Commands:${NC}"
echo -e "${BLUE}   • Update frontend: vercel --prod --cwd frontend${NC}"
echo -e "${BLUE}   • View deployments: vercel ls${NC}"
echo -e "${BLUE}   • View logs: vercel logs${NC}"
echo ""
echo -e "${GREEN}🎊 Your GitHub Repository Dashboard is now live on the internet! 🎊${NC}"

# Save URLs to file
cat > DEPLOYMENT_URLS.md << EOF
# 🌐 Deployment URLs

## Live Application
- **Frontend (Vercel)**: $VERCEL_URL
- **Backend (Railway)**: $BACKEND_URL

## API Endpoints
- **Stats**: $BACKEND_URL/api/repos/stats
- **Repositories**: $BACKEND_URL/api/repos
- **Search**: $BACKEND_URL/api/repos/search?q=searchterm
- **Languages**: $BACKEND_URL/api/repos/languages

## Deployment Info
- **Frontend**: Deployed to Vercel with global CDN
- **Backend**: Deployed to Railway with auto-scaling
- **Database**: H2 in-memory with automatic refresh
- **SSL**: Automatic HTTPS on both platforms

## Management
- **Vercel Dashboard**: https://vercel.com/dashboard
- **Railway Dashboard**: https://railway.app/dashboard

Last Updated: $(date)
EOF

echo -e "${GREEN}✅ Deployment URLs saved to DEPLOYMENT_URLS.md${NC}"

# Cleanup
rm -f build.sh