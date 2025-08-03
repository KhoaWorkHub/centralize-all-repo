#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛑 Stopping GitHub Repository Dashboard${NC}"
echo -e "${BLUE}=====================================${NC}"

# Stop and remove containers
echo -e "${YELLOW}📦 Stopping and removing containers...${NC}"

if docker compose version > /dev/null 2>&1; then
    docker compose down --remove-orphans
elif command -v docker-compose > /dev/null 2>&1; then
    docker-compose down --remove-orphans
else
    echo -e "${RED}❌ Error: Neither 'docker compose' nor 'docker-compose' command found.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All services stopped successfully!${NC}"
echo ""
echo -e "${BLUE}📝 To start again, run:${NC}"
echo -e "${BLUE}   ./start.sh${NC}"