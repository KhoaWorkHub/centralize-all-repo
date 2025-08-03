#!/bin/bash

set -e

# Colors for output
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 GitHub Repository Dashboard - Live Logs${NC}"
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}Press Ctrl+C to stop viewing logs${NC}"
echo ""

# Show logs for all services
if docker compose version > /dev/null 2>&1; then
    docker compose logs -f
elif command -v docker-compose > /dev/null 2>&1; then
    docker-compose logs -f
else
    echo -e "${RED}❌ Error: Neither 'docker compose' nor 'docker-compose' command found.${NC}"
    exit 1
fi