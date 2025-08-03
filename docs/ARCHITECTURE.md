# Architecture Documentation 🏗️

This document provides a comprehensive overview of the GitHub Repository Dashboard architecture, design decisions, and system components.

## System Overview

The GitHub Repository Dashboard is a modern, full-stack web application built with a microservices architecture approach, containerized using Docker for easy deployment and scalability.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Load Balancer / CDN                            │
│                                (Nginx/CloudFlare)                          │
└─────────────────────────┬───────────────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────────────┐
│                         Frontend Tier                                      │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────────────┐   │
│  │   React SPA     │   │  Nginx Proxy    │   │    Static Assets        │   │
│  │  (TypeScript)   │   │  (Port 3000)    │   │   (Images, CSS, JS)     │   │
│  │                 │   │                 │   │                         │   │
│  └─────────────────┘   └─────────────────┘   └─────────────────────────┘   │
└─────────────────────────┬───────────────────────────────────────────────────┘
                          │ HTTP/HTTPS
                          │ REST API Calls
┌─────────────────────────▼───────────────────────────────────────────────────┐
│                        Backend Tier                                        │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────────────┐   │
│  │  Spring Boot    │   │   REST APIs     │   │    Scheduled Tasks      │   │
│  │   Application   │   │  (Controllers)  │   │   (Auto-refresh)        │   │
│  │   (Port 8080)   │   │                 │   │                         │   │
│  └─────────────────┘   └─────────────────┘   └─────────────────────────┘   │
└─────────────────────────┬───────────────────────────────────────────────────┘
                          │
           ┌──────────────┼──────────────┐
           │              │              │
           ▼              ▼              ▼
┌─────────────────┐ ┌────────────┐ ┌──────────────────┐
│   Data Tier     │ │ Integration│ │   External APIs  │
│                 │ │    Tier    │ │                  │
│ ┌─────────────┐ │ │ ┌────────┐ │ │ ┌──────────────┐ │
│ │ H2 Database │ │ │ │Webhooks│ │ │ │ GitHub API   │ │
│ │(In-Memory)  │ │ │ │Handler │ │ │ │   (v3/v4)    │ │
│ └─────────────┘ │ │ └────────┘ │ │ └──────────────┘ │
└─────────────────┘ └────────────┘ └──────────────────┘
```

## Component Architecture

### Frontend Architecture (React + TypeScript)

```
frontend/
├── public/                     # Static assets
├── src/
│   ├── components/            # Reusable UI components
│   │   ├── ui/               # shadcn/ui base components
│   │   ├── RepositoryCard.tsx # Repository display component
│   │   ├── SearchBar.tsx     # Search functionality
│   │   └── FilterDropdown.tsx # Language filtering
│   ├── hooks/                # Custom React hooks
│   │   ├── useRepositories.ts # Repository data management
│   │   └── useDebounce.ts    # Search debouncing
│   ├── services/             # API communication
│   │   └── api.ts           # Axios-based API client
│   ├── types/               # TypeScript type definitions
│   │   └── repository.ts    # Repository interfaces
│   ├── utils/               # Utility functions
│   └── App.tsx             # Main application component
└── package.json            # Dependencies and scripts
```

#### Frontend Technology Stack

- **React 18**: Modern React with hooks and concurrent features
- **TypeScript**: Type safety and enhanced developer experience
- **Tailwind CSS**: Utility-first CSS framework
- **shadcn/ui**: Modern component library built on Radix UI
- **Axios**: HTTP client for API communication
- **Lucide React**: Modern icon library

#### State Management

```typescript
// Custom hook for repository management
const useRepositories = () => {
  const [repositories, setRepositories] = useState<Repository[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchRepositories = useCallback(async () => {
    try {
      setLoading(true);
      const data = await api.getRepositories();
      setRepositories(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, []);

  return { repositories, loading, error, fetchRepositories };
};
```

### Backend Architecture (Spring Boot + Java 21)

```
backend/
├── src/main/java/com/github/repodashboard/
│   ├── controller/           # REST API controllers
│   │   ├── RepositoryController.java  # Repository endpoints
│   │   └── WebhookController.java     # GitHub webhook handler
│   ├── service/             # Business logic layer
│   │   ├── GitHubService.java        # GitHub API integration
│   │   └── RepositoryService.java    # Repository business logic
│   ├── model/              # JPA entity models
│   │   └── Repository.java           # Repository entity
│   ├── repository/         # Data access layer
│   │   └── RepositoryRepository.java # JPA repository interface
│   ├── dto/               # Data transfer objects
│   │   └── GitHubRepository.java     # GitHub API response DTO
│   ├── config/            # Configuration classes
│   │   ├── CorsConfig.java          # CORS configuration
│   │   └── SchedulingConfig.java    # Task scheduling setup
│   └── RepodashboardApplication.java # Main application class
├── src/main/resources/
│   ├── application.properties       # Application configuration
│   └── data.sql                    # Initial data (if needed)
└── pom.xml                         # Maven dependencies
```

#### Backend Technology Stack

- **Spring Boot 3.2.1**: Modern Java framework with auto-configuration
- **Java 21**: Latest LTS version with modern language features
- **Spring Data JPA**: Data access abstraction
- **H2 Database**: In-memory database for development and demo
- **RestTemplate**: HTTP client for GitHub API integration
- **Spring Scheduling**: Automated task execution
- **Maven**: Dependency management and build tool

#### Layer Architecture

```java
// Controller Layer - REST API endpoints
@RestController
@RequestMapping("/api/repos")
public class RepositoryController {
    
    @GetMapping
    public List<Repository> getAllRepositories() {
        return repositoryService.getAllRepositories();
    }
    
    @GetMapping("/stats")
    public RepositoryStats getStats() {
        return repositoryService.getRepositoryStats();
    }
}

// Service Layer - Business logic
@Service
public class GitHubService {
    
    @Scheduled(fixedRate = 300000) // 5 minutes
    public void fetchAndCacheRepositories() {
        // GitHub API integration logic
    }
}

// Repository Layer - Data access
@Repository
public interface RepositoryRepository extends JpaRepository<Repository, Long> {
    List<Repository> findByLanguage(String language);
    
    @Query("SELECT DISTINCT r.language FROM Repository r WHERE r.language IS NOT NULL")
    List<String> findDistinctLanguages();
}
```

## Data Flow Architecture

### Request Flow Diagram

```
┌─────────────┐    1. HTTP Request    ┌─────────────────┐
│   Browser   │ ────────────────────► │  Nginx Proxy    │
│             │                       │  (Port 3000)    │
└─────────────┘                       └─────────────────┘
                                                │
                                                │ 2. Proxy to Backend
                                                ▼
┌─────────────┐    4. JSON Response   ┌─────────────────┐
│ React App   │ ◄──────────────────── │  Spring Boot    │
│             │                       │  (Port 8080)    │
└─────────────┘                       └─────────────────┘
                                                │
                                                │ 3. Database Query
                                                ▼
                                        ┌─────────────────┐
                                        │  H2 Database    │
                                        │  (In-Memory)    │
                                        └─────────────────┘
```

### GitHub API Integration Flow

```
┌─────────────────┐    1. Scheduled Task    ┌─────────────────┐
│ Spring Scheduler│ ──────────────────────► │  GitHubService  │
│   (5 minutes)   │                         │                 │
└─────────────────┘                         └─────────────────┘
                                                      │
                                                      │ 2. API Request
                                                      ▼
┌─────────────────┐    4. Store Data        ┌─────────────────┐
│  H2 Database    │ ◄──────────────────── │   GitHub API    │
│                 │                         │ (api.github.com)│
└─────────────────┘                         └─────────────────┘
         │                                            │
         │ 5. Serve Cached Data                      │ 3. JSON Response
         ▼                                            ▼
┌─────────────────┐                         ┌─────────────────┐
│ REST Controller │                         │  RestTemplate   │
│                 │                         │   HTTP Client   │
└─────────────────┘                         └─────────────────┘
```

## Database Schema

### Entity Relationship Diagram

```sql
┌─────────────────────────────────────────────────────────────┐
│                     REPOSITORIES                            │
├─────────────────────────────────────────────────────────────┤
│ id                    BIGINT         PRIMARY KEY            │
│ name                  VARCHAR(255)   NOT NULL               │
│ full_name             VARCHAR(500)   NOT NULL               │
│ description           TEXT           NULL                   │
│ html_url              VARCHAR(500)   NOT NULL               │
│ stargazers_count      INTEGER        NOT NULL DEFAULT 0     │
│ forks_count           INTEGER        NOT NULL DEFAULT 0     │
│ language              VARCHAR(100)   NULL                   │
│ created_at            TIMESTAMP      NOT NULL               │
│ updated_at            TIMESTAMP      NOT NULL               │
│ is_private            BOOLEAN        NOT NULL DEFAULT FALSE │
│ is_fork               BOOLEAN        NOT NULL DEFAULT FALSE │
└─────────────────────────────────────────────────────────────┘

Indexes:
- PRIMARY KEY (id)
- INDEX idx_language (language)
- INDEX idx_updated_at (updated_at)
- INDEX idx_name (name)
```

### JPA Entity Mapping

```java
@Entity
@Table(name = "repositories")
public class Repository {
    @Id
    private Long id;
    
    @Column(nullable = false)
    private String name;
    
    @Column(name = "full_name", nullable = false, length = 500)
    private String fullName;
    
    @Column(columnDefinition = "TEXT")
    private String description;
    
    @Column(name = "html_url", nullable = false, length = 500)
    private String htmlUrl;
    
    @Column(name = "stargazers_count", nullable = false)
    private Integer stargazersCount = 0;
    
    @Column(name = "forks_count", nullable = false)
    private Integer forksCount = 0;
    
    @Column(length = 100)
    private String language;
    
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
    
    @Column(name = "is_private", nullable = false)
    private Boolean isPrivate = false;
    
    @Column(name = "is_fork", nullable = false)
    private Boolean isFork = false;
}
```

## Security Architecture

### Authentication & Authorization

```
┌─────────────────┐    1. User Request    ┌─────────────────┐
│   Frontend      │ ────────────────────► │   Backend       │
│   (No Auth)     │                       │   (Public API)  │
└─────────────────┘                       └─────────────────┘
                                                    │
                                                    │ 2. GitHub API Call
                                                    ▼
┌─────────────────┐    3. Bearer Token    ┌─────────────────┐
│ GitHub Token    │ ────────────────────► │   GitHub API    │
│  (Environment)  │                       │  (Authenticated)│
└─────────────────┘                       └─────────────────┘
```

### Security Measures

1. **GitHub Token Security**:
   - Stored in environment variables
   - Never exposed to frontend
   - Configurable token scopes

2. **API Security**:
   - CORS configuration for allowed origins
   - No authentication required for dashboard API
   - Rate limiting through GitHub API limits

3. **Container Security**:
   - Non-root user in Docker containers
   - Minimal base images
   - Environment variable injection

4. **Network Security**:
   - HTTPS in production
   - Internal container networking
   - Configurable ports

## Performance Architecture

### Caching Strategy

```
┌─────────────────┐    1. Request         ┌─────────────────┐
│   Frontend      │ ────────────────────► │   Controller    │
└─────────────────┘                       └─────────────────┘
                                                    │
                                                    │ 2. Check Cache
                                                    ▼
┌─────────────────┐    3. Cached Data     ┌─────────────────┐
│  H2 Database    │ ◄──────────────────── │   Service       │
│   (In-Memory)   │                       │   Layer         │
└─────────────────┘                       └─────────────────┘
         │                                          │
         │ 4. If Empty                             │ 5. GitHub API
         ▼                                          ▼
┌─────────────────┐    6. Fresh Data      ┌─────────────────┐
│ GitHub API Call │ ────────────────────► │   GitHub API    │
│  (Rate Limited) │                       │  (External)     │
└─────────────────┘                       └─────────────────┘
```

### Performance Optimizations

1. **Database Performance**:
   - In-memory H2 database for fast access
   - Indexed columns for search operations
   - Batch updates for repository data

2. **API Performance**:
   - 5-minute scheduled refresh cycle
   - Cached repository data serving
   - Minimal GitHub API calls

3. **Frontend Performance**:
   - React component memoization
   - Debounced search functionality
   - Lazy loading for large lists

4. **Network Performance**:
   - Nginx gzip compression
   - Static asset caching
   - CDN-ready configuration

## Scalability Architecture

### Horizontal Scaling

```
┌─────────────────┐
│  Load Balancer  │
│   (Nginx/HAProxy)│
└─────────┬───────┘
          │
    ┌─────┼─────┐
    │     │     │
    ▼     ▼     ▼
┌─────┐ ┌─────┐ ┌─────┐
│App 1│ │App 2│ │App N│
└─────┘ └─────┘ └─────┘
    │     │     │
    └─────┼─────┘
          │
    ┌─────▼─────┐
    │ Shared DB │
    │(PostgreSQL)│
    └───────────┘
```

### Production Scaling Considerations

1. **Database Scaling**:
   - Replace H2 with PostgreSQL/MySQL
   - Database connection pooling
   - Read replicas for query performance

2. **Application Scaling**:
   - Stateless application design
   - Container orchestration (Kubernetes)
   - Auto-scaling based on metrics

3. **Caching Scaling**:
   - Redis for distributed caching
   - CDN for static assets
   - API response caching

4. **Monitoring & Observability**:
   - Application metrics (Prometheus)
   - Distributed tracing (Jaeger)
   - Centralized logging (ELK stack)

## Deployment Architecture

### Container Architecture

```dockerfile
# Multi-stage build for optimized images
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

### Docker Compose Architecture

```yaml
services:
  backend:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/repos/stats"]
      interval: 30s
      timeout: 10s
      retries: 5

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    depends_on:
      backend:
        condition: service_healthy
```

## Monitoring Architecture

### Application Monitoring

```
┌─────────────────┐    Metrics     ┌─────────────────┐
│  Spring Boot    │ ──────────────► │   Prometheus    │
│   Application   │                 │                 │
└─────────────────┘                 └─────────────────┘
         │                                    │
         │ Logs                              │ Queries
         ▼                                    ▼
┌─────────────────┐                 ┌─────────────────┐
│   ELK Stack     │                 │    Grafana      │
│ (Elasticsearch, │                 │   Dashboard     │
│  Logstash,      │                 │                 │
│  Kibana)        │                 │                 │
└─────────────────┘                 └─────────────────┘
```

### Key Metrics

1. **Application Metrics**:
   - Response times
   - Error rates
   - GitHub API rate limit usage
   - Repository count trends

2. **System Metrics**:
   - CPU and memory usage
   - Database connection pool
   - Container health status

3. **Business Metrics**:
   - Total repositories tracked
   - User engagement metrics
   - Search query patterns

## Technology Decisions

### Backend Framework Choice

**Spring Boot** was chosen for:
- **Rapid Development**: Auto-configuration and starter dependencies
- **Enterprise Grade**: Production-ready features out of the box
- **Ecosystem**: Rich ecosystem of integrations
- **Documentation**: Extensive documentation and community support

### Database Choice

**H2 In-Memory** for development/demo:
- **Zero Configuration**: No setup required
- **Fast Performance**: In-memory storage
- **Development Friendly**: Built-in web console

**PostgreSQL** recommended for production:
- **ACID Compliance**: Data integrity
- **JSON Support**: Native JSON column types
- **Scalability**: Excellent performance at scale

### Frontend Framework Choice

**React + TypeScript** was chosen for:
- **Type Safety**: TypeScript prevents runtime errors
- **Component Reusability**: Modular component architecture
- **Modern Development**: Hooks and functional components
- **Ecosystem**: Rich ecosystem of libraries and tools

### Containerization

**Docker + Docker Compose** provides:
- **Environment Consistency**: Same environment across dev/prod
- **Easy Deployment**: One-command deployment
- **Isolation**: Service isolation and resource management
- **Scalability**: Easy horizontal scaling

This architecture provides a solid foundation for the GitHub Repository Dashboard with clear separation of concerns, scalability options, and production-ready patterns.