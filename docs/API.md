# API Reference 📚

Complete API documentation for the GitHub Repository Dashboard backend services.

## Base URL

```
http://localhost:8080/api
```

For production deployments, replace `localhost:8080` with your deployed backend URL.

## Authentication

The API uses GitHub Personal Access Token for authentication with the GitHub API. No authentication is required for accessing the dashboard API endpoints.

## Rate Limiting

The application respects GitHub API rate limits:
- **Authenticated requests**: 5,000 requests per hour
- **Unauthenticated requests**: 60 requests per hour

The application automatically refreshes repository data every 5 minutes to minimize API calls.

## Repository Endpoints

### Get All Repositories

Retrieves all repositories for the authenticated GitHub user.

```http
GET /api/repos
```

#### Response

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

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Unique repository ID from GitHub |
| `name` | string | Repository name |
| `fullName` | string | Full repository name (owner/repo) |
| `description` | string | Repository description (can be null) |
| `htmlUrl` | string | GitHub repository URL |
| `stargazersCount` | number | Number of stars |
| `forksCount` | number | Number of forks |
| `language` | string | Primary programming language |
| `createdAt` | string | ISO date when repository was created |
| `updatedAt` | string | ISO date when repository was last updated |
| `isPrivate` | boolean | Whether repository is private |
| `isFork` | boolean | Whether repository is a fork |

### Get Repository Statistics

Retrieves aggregated statistics for all repositories.

```http
GET /api/repos/stats
```

#### Response

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

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `totalRepositories` | number | Total number of repositories |
| `totalStars` | number | Sum of all stars across repositories |
| `totalForks` | number | Sum of all forks across repositories |
| `publicRepositories` | number | Number of public repositories |
| `privateRepositories` | number | Number of private repositories |
| `forkedRepositories` | number | Number of forked repositories |

### Search Repositories

Search repositories by name, description, or other text content.

```http
GET /api/repos/search?q={search_term}
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | Yes | Search term to match against repository name, description, and full name |

#### Example Request

```http
GET /api/repos/search?q=react
```

#### Response

Returns an array of repositories matching the search criteria (same format as `/api/repos`).

### Filter Repositories by Language

Filter repositories by programming language.

```http
GET /api/repos/filter?language={language}
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `language` | string | Yes | Programming language to filter by (case-sensitive) |

#### Example Request

```http
GET /api/repos/filter?language=JavaScript
```

#### Response

Returns an array of repositories with the specified language (same format as `/api/repos`).

### Get Available Languages

Retrieves a list of all programming languages used across repositories.

```http
GET /api/repos/languages
```

#### Response

```json
[
  "JavaScript",
  "TypeScript",
  "Java",
  "Python",
  "HTML",
  "CSS"
]
```

## Webhook Endpoints

### GitHub Webhook

Endpoint for receiving GitHub webhook events to trigger real-time repository updates.

```http
POST /webhook/github
```

#### Headers

```http
Content-Type: application/json
X-GitHub-Event: {event_type}
X-GitHub-Delivery: {delivery_id}
X-Hub-Signature-256: {signature}
```

#### Supported Events

- `repository` - Repository created, deleted, or updated
- `push` - Code pushed to repository
- `create` - Branch or tag created
- `delete` - Branch or tag deleted

#### Request Body

The request body varies depending on the GitHub event. See [GitHub Webhook Events](https://docs.github.com/en/developers/webhooks-and-events/webhooks/webhook-events-and-payloads) for detailed payload structures.

#### Response

```http
200 OK
Content-Type: text/plain

Webhook received
```

#### Setting Up Webhooks

1. Go to your GitHub repository settings
2. Navigate to "Webhooks"
3. Click "Add webhook"
4. Set payload URL to `https://your-domain.com/webhook/github`
5. Select "application/json" as content type
6. Choose events: Repository, Push, Create, Delete
7. Click "Add webhook"

## Error Responses

All endpoints may return the following error responses:

### 400 Bad Request

Invalid request parameters or malformed request.

```json
{
  "error": "Bad Request",
  "message": "Invalid search parameter",
  "timestamp": "2024-01-20T15:30:00Z"
}
```

### 500 Internal Server Error

Server error, often related to GitHub API issues.

```json
{
  "error": "Internal Server Error",
  "message": "Failed to fetch repositories from GitHub API",
  "timestamp": "2024-01-20T15:30:00Z"
}
```

### 503 Service Unavailable

Service temporarily unavailable, usually during startup.

```json
{
  "error": "Service Unavailable",
  "message": "Application is starting up",
  "timestamp": "2024-01-20T15:30:00Z"
}
```

## Data Refresh

### Automatic Refresh

The application automatically refreshes repository data every 5 minutes using Spring's `@Scheduled` annotation:

```java
@Scheduled(fixedRate = 300000) // 5 minutes
public void scheduledRepositoryRefresh() {
    fetchAndCacheRepositories();
}
```

### Manual Refresh

To manually trigger a data refresh, restart the application or wait for the next scheduled refresh.

### Cache Behavior

- **Database**: H2 in-memory database stores cached repository data
- **Refresh Strategy**: Complete replacement of all repository data
- **Performance**: First request after startup may be slower as data is fetched from GitHub

## CORS Configuration

The API is configured to accept requests from the frontend application:

```properties
spring.web.cors.allowed-origins=http://localhost:3000
spring.web.cors.allowed-methods=GET,POST,PUT,DELETE,OPTIONS
spring.web.cors.allowed-headers=*
spring.web.cors.allow-credentials=true
```

For production, update the allowed origins to match your frontend domain.

## Health Checks

### Application Health

```http
GET /api/repos/stats
```

This endpoint serves as a health check. A successful response indicates:
- Application is running
- Database is accessible
- GitHub API integration is working

### Database Health

The H2 database console is available at:
```
http://localhost:8080/h2-console
```

**Connection Details:**
- JDBC URL: `jdbc:h2:mem:testdb`
- Username: `sa`
- Password: `password`

## Performance Considerations

### Response Times

Typical response times:
- **First request**: 2-5 seconds (GitHub API fetch)
- **Cached requests**: 50-200ms
- **Search/filter**: 10-50ms

### Memory Usage

- **H2 Database**: Stores repository data in memory
- **Typical memory usage**: 100-500MB depending on repository count
- **JVM heap**: Recommended 512MB minimum

### Scaling

For high-traffic scenarios, consider:
- **Database**: Switch to PostgreSQL or MySQL
- **Caching**: Add Redis for query caching
- **Load Balancing**: Multiple application instances
- **CDN**: Cache static responses

## SDK Examples

### JavaScript/TypeScript

```typescript
class GitHubDashboardAPI {
  private baseURL: string;

  constructor(baseURL = 'http://localhost:8080/api') {
    this.baseURL = baseURL;
  }

  async getRepositories(): Promise<Repository[]> {
    const response = await fetch(`${this.baseURL}/repos`);
    return response.json();
  }

  async getStats(): Promise<RepositoryStats> {
    const response = await fetch(`${this.baseURL}/repos/stats`);
    return response.json();
  }

  async searchRepositories(query: string): Promise<Repository[]> {
    const response = await fetch(`${this.baseURL}/repos/search?q=${encodeURIComponent(query)}`);
    return response.json();
  }

  async filterByLanguage(language: string): Promise<Repository[]> {
    const response = await fetch(`${this.baseURL}/repos/filter?language=${encodeURIComponent(language)}`);
    return response.json();
  }

  async getLanguages(): Promise<string[]> {
    const response = await fetch(`${this.baseURL}/repos/languages`);
    return response.json();
  }
}

// Usage
const api = new GitHubDashboardAPI();
const repositories = await api.getRepositories();
const stats = await api.getStats();
```

### Python

```python
import requests
from typing import List, Dict

class GitHubDashboardAPI:
    def __init__(self, base_url: str = "http://localhost:8080/api"):
        self.base_url = base_url

    def get_repositories(self) -> List[Dict]:
        response = requests.get(f"{self.base_url}/repos")
        response.raise_for_status()
        return response.json()

    def get_stats(self) -> Dict:
        response = requests.get(f"{self.base_url}/repos/stats")
        response.raise_for_status()
        return response.json()

    def search_repositories(self, query: str) -> List[Dict]:
        response = requests.get(f"{self.base_url}/repos/search", params={"q": query})
        response.raise_for_status()
        return response.json()

    def filter_by_language(self, language: str) -> List[Dict]:
        response = requests.get(f"{self.base_url}/repos/filter", params={"language": language})
        response.raise_for_status()
        return response.json()

    def get_languages(self) -> List[str]:
        response = requests.get(f"{self.base_url}/repos/languages")
        response.raise_for_status()
        return response.json()

# Usage
api = GitHubDashboardAPI()
repositories = api.get_repositories()
stats = api.get_stats()
```

### cURL Examples

```bash
# Get all repositories
curl -X GET "http://localhost:8080/api/repos"

# Get statistics
curl -X GET "http://localhost:8080/api/repos/stats"

# Search repositories
curl -X GET "http://localhost:8080/api/repos/search?q=react"

# Filter by language
curl -X GET "http://localhost:8080/api/repos/filter?language=JavaScript"

# Get available languages
curl -X GET "http://localhost:8080/api/repos/languages"

# Test webhook endpoint
curl -X POST "http://localhost:8080/webhook/github" \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: repository" \
  -d '{"action": "created", "repository": {"name": "test"}}'
```

## OpenAPI/Swagger Documentation

For interactive API documentation, access the Swagger UI at:
```
http://localhost:8080/swagger-ui.html
```

The OpenAPI specification is available at:
```
http://localhost:8080/v3/api-docs
```

## Changelog

### v1.0.0
- Initial API release
- Repository CRUD operations
- GitHub webhook integration
- Statistics endpoints
- Search and filtering capabilities

---

For more information or support, please refer to the main [README.md](../README.md) or create an issue in the GitHub repository.