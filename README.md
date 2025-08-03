# GitHub Repository Dashboard 📊

A modern, full-stack web application that provides a centralized dashboard for viewing and managing all your GitHub repositories. Built with Spring Boot backend and React TypeScript frontend, containerized with Docker for easy deployment.

![Dashboard Preview](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)
![Java](https://img.shields.io/badge/Java-21-orange)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2.1-brightgreen)
![React](https://img.shields.io/badge/React-18-blue)
![TypeScript](https://img.shields.io/badge/TypeScript-5.0-blue)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)

## ✨ Features

### Core Functionality
- **📋 Repository Listing**: Automatically fetches and displays all your GitHub repositories
- **🔍 Real-time Search**: Search repositories by name, description, or language
- **🏷️ Language Filtering**: Filter repositories by programming language
- **📊 Statistics Dashboard**: View comprehensive stats (total repos, stars, forks, etc.)
- **🔄 Auto-refresh**: Repositories are automatically updated every 5 minutes
- **🎯 Responsive Design**: Works perfectly on desktop, tablet, and mobile devices

### Technical Features
- **🔐 Secure Authentication**: Uses GitHub Personal Access Token
- **⚡ Fast Performance**: In-memory H2 database for quick data access
- **🐳 Containerized**: Complete Docker setup with one-command deployment
- **🔗 GitHub Webhooks**: Real-time updates when repositories change
- **🎨 Modern UI**: Built with Tailwind CSS and shadcn/ui components
- **📱 PWA Ready**: Progressive Web App capabilities

## 🚀 Quick Start

### Prerequisites
- **Docker & Docker Compose**: [Install Docker](https://docs.docker.com/get-docker/)
- **GitHub Personal Access Token**: [Generate Token](https://github.com/settings/tokens)
  - Required scopes: `repo` (for accessing private repositories) or `public_repo` (for public only)

### One-Command Setup

1. **Clone the repository**:
```bash
git clone https://github.com/yourusername/github-repo-dashboard.git
cd github-repo-dashboard
```

2. **Configure your GitHub token**:
```bash
# Edit .env file and add your GitHub token
echo "GITHUB_TOKEN=your_github_personal_access_token_here" > .env
```

3. **Start the application**:
```bash
chmod +x start.sh
./start.sh
```

4. **Access the dashboard**:
- Frontend: http://localhost:3000
- Backend API: http://localhost:8080/api
- H2 Database Console: http://localhost:8080/h2-console

## 🏗️ Architecture

### System Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   React App     │◄───┤   Nginx Proxy   │◄───┤  Spring Boot    │
│  (Port 3000)    │    │                 │    │   (Port 8080)   │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│  GitHub API     │◄───┤  RestTemplate   │◄───┤  H2 Database    │
│                 │    │   HTTP Client   │    │   (In-Memory)   │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Tech Stack

#### Backend
- **Framework**: Spring Boot 3.2.1 with Java 21
- **Database**: H2 In-Memory Database with JPA/Hibernate
- **HTTP Client**: RestTemplate for GitHub API integration
- **Scheduler**: Spring Scheduling for auto-refresh
- **Build Tool**: Maven 3.9.6

#### Frontend
- **Framework**: React 18 with TypeScript
- **Styling**: Tailwind CSS + shadcn/ui components
- **HTTP Client**: Axios for API communication
- **Icons**: Lucide React icons
- **Build Tool**: Create React App

#### Infrastructure
- **Containerization**: Docker & Docker Compose
- **Web Server**: Nginx (production-ready configuration)
- **Process Management**: Docker health checks and restart policies

## 📖 API Documentation

### Base URL
```
http://localhost:8080/api
```

### Endpoints

#### Repository Endpoints
```http
GET /api/repos
# Returns: List of all repositories with full details

GET /api/repos/stats  
# Returns: Repository statistics (total, stars, forks, etc.)

GET /api/repos/search?q={search_term}
# Returns: Repositories matching search term

GET /api/repos/filter?language={language}
# Returns: Repositories filtered by programming language

GET /api/repos/languages
# Returns: List of all available programming languages
```

#### Webhook Endpoints
```http
POST /webhook/github
# GitHub webhook endpoint for real-time updates
# Requires GitHub webhook configuration
```

### Response Examples

#### Repository List Response
```json
[
  {
    "id": 123456789,
    "name": "my-awesome-project",
    "fullName": "username/my-awesome-project",
    "description": "An awesome project description",
    "htmlUrl": "https://github.com/username/my-awesome-project",
    "stargazersCount": 42,
    "forksCount": 7,
    "language": "TypeScript",
    "createdAt": "2024-01-15T10:30:00",
    "updatedAt": "2024-01-20T14:45:00",
    "isPrivate": false,
    "isFork": false
  }
]
```

#### Statistics Response
```json
{
  "totalRepositories": 25,
  "totalStars": 150,
  "totalForks": 45,
  "publicRepositories": 20,
  "privateRepositories": 5,
  "forkedRepositories": 8
}
```

## 🔧 Configuration

### Environment Variables

#### Backend Configuration (application.properties)
```properties
# Server Configuration
server.port=8080

# Database Configuration  
spring.datasource.url=jdbc:h2:mem:testdb
spring.h2.console.enabled=true

# GitHub API Configuration
github.token=${GITHUB_TOKEN}
github.api.base-url=https://api.github.com
```

#### Docker Environment (.env)
```bash
# Required: Your GitHub Personal Access Token
GITHUB_TOKEN=github_pat_11EXAMPLE_TOKEN_HERE

# Optional: Production settings
NODE_ENV=production
```

### GitHub Token Setup

1. Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Select scopes:
   - `repo` - Full control of private repositories (recommended)
   - OR `public_repo` - Access to public repositories only
4. Copy the generated token to your `.env` file

## 🚀 Deployment Options

### Free Hosting Solutions

#### 1. Railway (Recommended)
- **Cost**: Free tier with 500 hours/month
- **Features**: Auto-deploy from GitHub, managed databases
- **Setup**: Connect GitHub repo, Railway auto-detects Docker

```bash
# Install Railway CLI
npm install -g @railway/cli

# Deploy
railway login
railway link
railway up
```

#### 2. Render
- **Cost**: Free tier for web services
- **Features**: Auto-deploy, managed PostgreSQL
- **Setup**: Connect GitHub repo, Render builds automatically

#### 3. Heroku
- **Cost**: Free tier discontinued, paid plans start at $5/month
- **Features**: Add-ons ecosystem, easy scaling

#### 4. Docker + VPS
- **Cost**: $5-10/month for basic VPS
- **Providers**: DigitalOcean, Linode, Vultr
- **Setup**: Copy project files, run `./start.sh`

### Production Deployment

#### Environment Setup
```bash
# Production environment variables
NODE_ENV=production
GITHUB_TOKEN=your_production_token
SPRING_PROFILES_ACTIVE=production
```

#### SSL/HTTPS Setup
```nginx
# Add to nginx.conf for SSL
listen 443 ssl;
ssl_certificate /path/to/cert.pem;
ssl_certificate_key /path/to/private.key;
```

## 🔄 GitHub Webhooks (Optional)

Set up real-time repository updates:

1. Go to your GitHub repository settings
2. Navigate to Webhooks
3. Add webhook URL: `https://your-domain.com/webhook/github`
4. Select events: `Repository`, `Push`, `Create`, `Delete`
5. Set content type to `application/json`

## 🛠️ Development

### Local Development Setup

#### Backend Development
```bash
cd backend
./mvnw spring-boot:run
# Backend runs on http://localhost:8080
```

#### Frontend Development  
```bash
cd frontend
npm install
npm start
# Frontend runs on http://localhost:3000
```

#### Database Access
```bash
# H2 Console: http://localhost:8080/h2-console
# JDBC URL: jdbc:h2:mem:testdb
# Username: sa
# Password: password
```

### Project Structure
```
github-repo-dashboard/
├── backend/                 # Spring Boot application
│   ├── src/main/java/      # Java source code
│   ├── src/main/resources/ # Configuration files
│   ├── Dockerfile          # Backend container config
│   └── pom.xml            # Maven dependencies
├── frontend/               # React application
│   ├── src/               # React source code
│   ├── public/            # Static assets
│   ├── Dockerfile         # Frontend container config
│   └── package.json       # NPM dependencies
├── docs/                  # Documentation
├── docker-compose.yml     # Multi-container setup
├── start.sh              # One-command deployment
├── .env                  # Environment variables
└── README.md            # This file
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support & Troubleshooting

### Common Issues

#### 1. GitHub API Rate Limits
- **Issue**: API requests failing with 403 errors
- **Solution**: Ensure your GitHub token has proper scopes and isn't rate-limited

#### 2. Docker Build Failures
- **Issue**: Docker build fails or containers don't start
- **Solution**: Run `docker system prune -a` to clean up, then rebuild

#### 3. Empty Repository List
- **Issue**: No repositories showing in the dashboard
- **Solution**: Check GitHub token permissions and backend logs

#### 4. Frontend Not Loading
- **Issue**: Frontend shows blank page or errors
- **Solution**: Check if backend is running and accessible at port 8080

### Getting Help

- **Issues**: [GitHub Issues](https://github.com/yourusername/github-repo-dashboard/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/github-repo-dashboard/discussions)
- **Documentation**: Check the `/docs` folder for detailed guides

## 🎯 Roadmap

### Upcoming Features
- [ ] GitHub Organizations support
- [ ] Repository analytics and insights
- [ ] Bulk repository operations
- [ ] Team collaboration features
- [ ] Custom dashboard layouts
- [ ] Integration with other Git platforms
- [ ] Mobile app (React Native)

### Performance Improvements
- [ ] PostgreSQL support for production
- [ ] Redis caching layer
- [ ] GraphQL API implementation
- [ ] Real-time WebSocket updates

---

**Made with ❤️ by [Your Name]**

⭐ Star this repository if you find it helpful!