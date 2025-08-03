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

# Service management script for GitHub Repository Dashboard

show_banner() {
    echo -e "${PURPLE}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║              GitHub Repository Dashboard                     ║"
    echo "  ║                 Service Management                           ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_usage() {
    echo -e "${BLUE}Usage: $0 {start|stop|restart|status|logs|clean|update|help}${NC}"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  ${GREEN}start${NC}     - Start all services"
    echo -e "  ${GREEN}stop${NC}      - Stop all services"
    echo -e "  ${GREEN}restart${NC}   - Restart all services"
    echo -e "  ${GREEN}status${NC}    - Show service status"
    echo -e "  ${GREEN}logs${NC}      - Show service logs"
    echo -e "  ${GREEN}clean${NC}     - Clean up containers and images"
    echo -e "  ${GREEN}update${NC}    - Update and rebuild services"
    echo -e "  ${GREEN}help${NC}      - Show this help message"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "  $0 start           # Start all services"
    echo -e "  $0 logs backend    # Show backend logs"
    echo -e "  $0 logs --follow   # Follow all logs"
    echo -e "  $0 clean --all     # Clean everything including volumes"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: Docker is not running. Please start Docker and try again.${NC}"
        exit 1
    fi
}

# Determine Docker Compose command
get_compose_cmd() {
    if docker compose version > /dev/null 2>&1; then
        echo "docker compose"
    elif command -v docker-compose > /dev/null 2>&1; then
        echo "docker-compose"
    else
        echo -e "${RED}❌ Error: Neither 'docker compose' nor 'docker-compose' command found.${NC}"
        exit 1
    fi
}

# Check environment setup
check_environment() {
    if [ ! -f .env ]; then
        echo -e "${YELLOW}⚠️  .env file not found. Creating from template...${NC}"
        if [ -f .env.example ]; then
            cp .env.example .env
        else
            echo "GITHUB_TOKEN=your_github_personal_access_token_here" > .env
        fi
        echo -e "${YELLOW}📝 Please edit .env file and add your GitHub Personal Access Token${NC}"
        echo -e "${YELLOW}   Get one from: https://github.com/settings/tokens${NC}"
        return 1
    fi

    # Load environment variables
    set -a
    source .env
    set +a

    if [ -z "$GITHUB_TOKEN" ] || [ "$GITHUB_TOKEN" = "your_github_personal_access_token_here" ]; then
        echo -e "${RED}❌ GitHub token not configured in .env file${NC}"
        return 1
    fi

    return 0
}

# Start services
start_services() {
    echo -e "${YELLOW}🚀 Starting GitHub Repository Dashboard...${NC}"
    
    check_docker
    if ! check_environment; then
        exit 1
    fi

    local compose_cmd=$(get_compose_cmd)
    
    echo -e "${YELLOW}📦 Building and starting services...${NC}"
    $compose_cmd up --build -d

    echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
    
    # Wait for backend
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "http://localhost:8080/api/repos/stats" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Backend is ready!${NC}"
            break
        fi
        if [ $attempt -eq $max_attempts ]; then
            echo -e "${RED}❌ Backend failed to start within expected time${NC}"
            show_logs backend
            exit 1
        fi
        echo -e "${YELLOW}   Waiting for backend... ($attempt/$max_attempts)${NC}"
        sleep 2
        attempt=$((attempt + 1))
    done

    # Wait for frontend
    attempt=1
    while [ $attempt -le 30 ]; do
        if curl -s -f "http://localhost:3000" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Frontend is ready!${NC}"
            break
        fi
        if [ $attempt -eq 30 ]; then
            echo -e "${RED}❌ Frontend failed to start within expected time${NC}"
            show_logs frontend
            exit 1
        fi
        echo -e "${YELLOW}   Waiting for frontend... ($attempt/30)${NC}"
        sleep 2
        attempt=$((attempt + 1))
    done

    echo ""
    echo -e "${GREEN}🎉 SUCCESS! All services are running!${NC}"
    echo ""
    echo -e "${CYAN}🌐 Application URLs:${NC}"
    echo -e "  ${BLUE}• Frontend:${NC}     http://localhost:3000"
    echo -e "  ${BLUE}• Backend API:${NC}  http://localhost:8080"
    echo -e "  ${BLUE}• API Stats:${NC}    http://localhost:8080/api/repos/stats"
    echo -e "  ${BLUE}• H2 Console:${NC}   http://localhost:8080/h2-console"
    echo ""

    # Auto-open browser
    if command -v open > /dev/null 2>&1; then
        echo -e "${YELLOW}🌐 Opening browser...${NC}"
        sleep 2
        open http://localhost:3000
    elif command -v xdg-open > /dev/null 2>&1; then
        echo -e "${YELLOW}🌐 Opening browser...${NC}"
        sleep 2
        xdg-open http://localhost:3000
    fi
}

# Stop services
stop_services() {
    echo -e "${YELLOW}🛑 Stopping GitHub Repository Dashboard...${NC}"
    
    check_docker
    local compose_cmd=$(get_compose_cmd)
    
    $compose_cmd down --remove-orphans
    
    echo -e "${GREEN}✅ All services stopped successfully!${NC}"
}

# Restart services
restart_services() {
    echo -e "${YELLOW}🔄 Restarting GitHub Repository Dashboard...${NC}"
    stop_services
    echo ""
    start_services
}

# Show service status
show_status() {
    echo -e "${YELLOW}📊 Service Status:${NC}"
    echo ""
    
    check_docker
    local compose_cmd=$(get_compose_cmd)
    
    $compose_cmd ps
    
    echo ""
    echo -e "${YELLOW}🔗 Health Checks:${NC}"
    
    # Check backend
    if curl -s -f "http://localhost:8080/api/repos/stats" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Backend API:${NC} http://localhost:8080 - Healthy"
    else
        echo -e "  ${RED}❌ Backend API:${NC} http://localhost:8080 - Not responding"
    fi
    
    # Check frontend
    if curl -s -f "http://localhost:3000" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Frontend:${NC}    http://localhost:3000 - Healthy"
    else
        echo -e "  ${RED}❌ Frontend:${NC}    http://localhost:3000 - Not responding"
    fi
    
    echo ""
    echo -e "${YELLOW}💾 Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null | grep -E "(github-repo|CONTAINER)" || echo "No containers running"
}

# Show logs
show_logs() {
    local service=$1
    local follow_flag=$2
    
    check_docker
    local compose_cmd=$(get_compose_cmd)
    
    if [ "$service" = "--follow" ] || [ "$follow_flag" = "--follow" ]; then
        echo -e "${YELLOW}📝 Following logs for all services (Ctrl+C to stop):${NC}"
        $compose_cmd logs -f
    elif [ -n "$service" ] && [ "$service" != "--follow" ]; then
        echo -e "${YELLOW}📝 Showing logs for $service:${NC}"
        $compose_cmd logs "$service"
    else
        echo -e "${YELLOW}📝 Showing logs for all services:${NC}"
        $compose_cmd logs
    fi
}

# Clean up
clean_services() {
    local clean_level=$1
    
    echo -e "${YELLOW}🧹 Cleaning up Docker resources...${NC}"
    
    check_docker
    local compose_cmd=$(get_compose_cmd)
    
    # Stop and remove containers
    $compose_cmd down --remove-orphans
    
    if [ "$clean_level" = "--all" ]; then
        echo -e "${YELLOW}🗑️  Removing all containers, images, and volumes...${NC}"
        
        # Remove project containers
        docker container ls -a --filter "name=github-repo" --format "{{.ID}}" | xargs -r docker container rm -f
        
        # Remove project images
        docker image ls --filter "reference=*github-repo*" --format "{{.ID}}" | xargs -r docker image rm -f
        
        # Remove unused volumes
        docker volume prune -f
        
        # Remove unused networks
        docker network prune -f
        
        echo -e "${GREEN}✅ Deep cleanup completed!${NC}"
    else
        echo -e "${YELLOW}🧹 Removing orphaned containers and networks...${NC}"
        docker container prune -f
        docker network prune -f
        echo -e "${GREEN}✅ Basic cleanup completed!${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}💡 To perform deep cleanup including images and volumes:${NC}"
    echo -e "${BLUE}   $0 clean --all${NC}"
}

# Update services
update_services() {
    echo -e "${YELLOW}🔄 Updating GitHub Repository Dashboard...${NC}"
    
    check_docker
    local compose_cmd=$(get_compose_cmd)
    
    # Pull latest base images
    echo -e "${YELLOW}📥 Pulling latest base images...${NC}"
    docker pull eclipse-temurin:21-jre-jammy
    docker pull maven:3.9.6-eclipse-temurin-21
    docker pull node:18-alpine
    docker pull nginx:alpine
    
    # Rebuild and restart
    echo -e "${YELLOW}🔨 Rebuilding services...${NC}"
    $compose_cmd build --no-cache
    
    restart_services
    
    echo -e "${GREEN}✅ Update completed!${NC}"
}

# Show detailed help
show_help() {
    show_usage
    echo ""
    echo -e "${YELLOW}📚 Additional Information:${NC}"
    echo ""
    echo -e "${CYAN}Configuration:${NC}"
    echo -e "  • Environment variables are loaded from .env file"
    echo -e "  • GitHub token is required for API access"
    echo -e "  • Ports used: 3000 (frontend), 8080 (backend)"
    echo ""
    echo -e "${CYAN}Troubleshooting:${NC}"
    echo -e "  • Check logs: $0 logs [service]"
    echo -e "  • Check status: $0 status"
    echo -e "  • Clean and restart: $0 clean && $0 start"
    echo ""
    echo -e "${CYAN}Development:${NC}"
    echo -e "  • Backend development: cd backend && ./mvnw spring-boot:run"
    echo -e "  • Frontend development: cd frontend && npm start"
    echo ""
    echo -e "${CYAN}Files:${NC}"
    echo -e "  • Configuration: .env"
    echo -e "  • Docker setup: docker-compose.yml"
    echo -e "  • Documentation: README.md, docs/"
}

# Main script
main() {
    show_banner
    
    case "$1" in
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$2" "$3"
            ;;
        clean)
            clean_services "$2"
            ;;
        update)
            update_services
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            echo -e "${RED}❌ No command specified${NC}"
            echo ""
            show_usage
            exit 1
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $1${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"