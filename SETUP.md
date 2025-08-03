# GitHub Repository Dashboard - Setup Guide

## Prerequisites

- Docker and Docker Compose installed
- GitHub Personal Access Token with repo permissions

## Quick Start

1. **Clone/Download the project**
   ```bash
   # If you haven't already, navigate to the project directory
   cd centralize-all-repo
   ```

2. **Configure GitHub Token**
   ```bash
   # Copy environment file
   cp .env.example .env
   
   # Edit .env file and set your GitHub token
   # Or export it as environment variable:
   export GITHUB_TOKEN=your_github_personal_access_token_here
   ```

3. **Start the application**
   ```bash
   ./start.sh
   ```

4. **Access the application**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8080

## Getting Your GitHub Token

1. Go to [GitHub Personal Access Tokens](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Select the following permissions:
   - `repo` (Full control of private repositories)
   - `public_repo` (Access public repositories)
4. Copy the generated token and add it to your `.env` file

## Manual Setup (Without Docker)

### Backend Development
```bash
cd backend
./mvnw spring-boot:run
```

### Frontend Development
```bash
cd frontend
npm install
npm start
```

## Available Scripts

- `./start.sh` - Start the entire application
- `./stop.sh` - Stop all services
- `./logs.sh` - View live logs from all services

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GITHUB_TOKEN` | GitHub Personal Access Token | Required |
| `NODE_ENV` | Environment mode | development |

### GitHub Webhooks (Optional)

To enable real-time updates when you create new repositories:

1. Go to your GitHub user settings > Developer settings > Webhooks
2. Add webhook URL: `http://your-domain:8080/webhook/github`
3. Content type: `application/json`
4. Select individual events: `Repositories`

## API Endpoints

### Repository Management
- `GET /api/repos` - Get all repositories
- `GET /api/repos?search=term` - Search repositories
- `GET /api/repos?language=JavaScript` - Filter by language
- `POST /api/repos/refresh` - Manually refresh repositories
- `GET /api/repos/stats` - Get repository statistics
- `GET /api/repos/languages` - Get available languages

### Webhooks
- `POST /webhook/github` - GitHub webhook endpoint
- `GET /webhook/github` - Webhook health check

## Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   # Stop any existing services
   ./stop.sh
   
   # Check what's using the port
   lsof -i :3000  # or :8080
   ```

2. **GitHub API rate limiting**
   - Make sure you're using a valid Personal Access Token
   - Authenticated requests have higher rate limits

3. **Docker issues**
   ```bash
   # Rebuild containers
   docker-compose build --no-cache
   
   # Remove all containers and volumes
   docker-compose down -v
   ```

4. **Frontend not loading**
   - Check if backend is running: http://localhost:8080/api/repos/stats
   - View logs: `./logs.sh`

### Health Checks

- Backend health: http://localhost:8080/api/repos/stats
- Frontend health: http://localhost:3000

## Development

### Project Structure
```
centralize-all-repo/
├── backend/                 # Spring Boot backend
│   ├── src/main/java/      # Java source code
│   ├── Dockerfile          # Backend Docker config
│   └── pom.xml            # Maven dependencies
├── frontend/               # React frontend
│   ├── src/               # React source code
│   ├── Dockerfile         # Frontend Docker config
│   └── package.json       # NPM dependencies
├── docker-compose.yml     # Docker orchestration
├── start.sh              # Startup script
└── README.md             # Main documentation
```

### Adding Features

1. **Backend API endpoints**: Add controllers in `backend/src/main/java/com/github/repodashboard/controller/`
2. **Frontend components**: Add React components in `frontend/src/components/`
3. **Database models**: Add entities in `backend/src/main/java/com/github/repodashboard/model/`

## Performance

- The application uses H2 in-memory database for fast startup
- Repository data is cached and refreshed every 5 minutes
- Frontend uses React with TypeScript for optimal performance
- Docker multi-stage builds minimize image sizes

## Security

- CORS is configured for localhost development
- GitHub webhooks are validated
- No sensitive data is logged
- Environment variables are used for configuration