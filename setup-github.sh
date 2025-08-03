#!/bin/bash

echo "🚀 GitHub Repository Setup Script"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed.${NC}"
    echo -e "${BLUE}📝 Please install it from: https://cli.github.com/${NC}"
    echo ""
    echo "Installation commands:"
    echo "  macOS: brew install gh"
    echo "  Ubuntu: sudo apt install gh"
    echo "  Windows: winget install GitHub.CLI"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}🔐 You need to authenticate with GitHub first${NC}"
    echo ""
    echo "Please run the following command and follow the prompts:"
    echo -e "${BLUE}gh auth login${NC}"
    echo ""
    echo "Then re-run this script."
    exit 1
fi

# Get repository name
echo -e "${BLUE}📝 What would you like to name your GitHub repository?${NC}"
echo "   (Default: github-repo-dashboard)"
read -p "Repository name: " REPO_NAME

if [ -z "$REPO_NAME" ]; then
    REPO_NAME="github-repo-dashboard"
fi

# Get repository visibility
echo ""
echo -e "${BLUE}🔒 Repository visibility:${NC}"
echo "1. Public (recommended for portfolio/demo)"
echo "2. Private"
read -p "Choose (1 or 2, default: 1): " VISIBILITY_CHOICE

if [ "$VISIBILITY_CHOICE" = "2" ]; then
    VISIBILITY="--private"
    VISIBILITY_TEXT="private"
else
    VISIBILITY="--public"
    VISIBILITY_TEXT="public"
fi

# Create repository description
DESCRIPTION="GitHub Repository Dashboard - A modern full-stack web application for managing and viewing GitHub repositories with real-time updates, built with Spring Boot and React."

echo ""
echo -e "${YELLOW}📋 Repository Summary:${NC}"
echo "  Name: $REPO_NAME"
echo "  Visibility: $VISIBILITY_TEXT"
echo "  Description: $DESCRIPTION"
echo ""

read -p "Create repository? (Y/n): " CONFIRM
if [[ $CONFIRM =~ ^[Nn]$ ]]; then
    echo "❌ Repository creation cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}🚀 Creating GitHub repository...${NC}"

# Create the repository
if gh repo create "$REPO_NAME" $VISIBILITY --description "$DESCRIPTION" --source=. --push; then
    echo ""
    echo -e "${GREEN}✅ Success! Repository created and code pushed!${NC}"
    echo ""
    echo -e "${BLUE}📄 Repository Information:${NC}"
    echo "  🌐 URL: https://github.com/$(gh api user --jq .login)/$REPO_NAME"
    echo "  📊 Dashboard: https://github.com/$(gh api user --jq .login)/$REPO_NAME/actions"
    echo "  📝 Issues: https://github.com/$(gh api user --jq .login)/$REPO_NAME/issues"
    echo ""
    echo -e "${YELLOW}🔧 Next Steps:${NC}"
    echo "1. Update the GitHub token in your .env file:"
    echo "   echo 'GITHUB_TOKEN=your_github_personal_access_token_here' > .env"
    echo ""
    echo "2. Deploy your application using one of these free options:"
    echo "   • Railway: railway.app (recommended)"
    echo "   • Render: render.com"
    echo "   • Fly.io: fly.io"
    echo ""
    echo "3. Check out the documentation:"
    echo "   • README.md - Project overview and setup"
    echo "   • docs/DEPLOYMENT.md - Deployment guides"
    echo "   • docs/API.md - API documentation"
    echo "   • docs/ARCHITECTURE.md - System architecture"
    echo ""
    echo -e "${GREEN}🎉 Your GitHub Repository Dashboard is ready to go!${NC}"
    
    # Open repository in browser (optional)
    read -p "Open repository in browser? (Y/n): " OPEN_BROWSER
    if [[ ! $OPEN_BROWSER =~ ^[Nn]$ ]]; then
        gh repo view --web
    fi
    
else
    echo ""
    echo -e "${RED}❌ Failed to create repository. Please check the error above.${NC}"
    echo ""
    echo "Common issues:"
    echo "1. Repository name already exists"
    echo "2. Authentication issues - try: gh auth login"
    echo "3. Network connectivity issues"
    exit 1
fi