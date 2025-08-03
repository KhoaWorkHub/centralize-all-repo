# Contributing Guide 🤝

Thank you for your interest in contributing to the GitHub Repository Dashboard! This guide will help you get started with contributing to the project.

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:
- **Docker & Docker Compose**: [Install Docker](https://docs.docker.com/get-docker/)
- **Node.js 18+**: For frontend development
- **Java 21**: For backend development
- **Git**: For version control

### Development Setup

1. **Fork the repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/github-repo-dashboard.git
   cd github-repo-dashboard
   ```

2. **Set up environment**
   ```bash
   # Copy environment template
   cp .env.example .env
   
   # Add your GitHub token
   echo "GITHUB_TOKEN=your_github_personal_access_token_here" >> .env
   ```

3. **Start development environment**
   ```bash
   # One-command setup
   ./start.sh
   
   # Or manually:
   docker-compose up -d
   ```

4. **Verify setup**
   - Frontend: http://localhost:3000
   - Backend: http://localhost:8080
   - API Docs: http://localhost:8080/swagger-ui.html
   - H2 Console: http://localhost:8080/h2-console

## Development Workflow

### Branch Strategy

We use a simple branching strategy:
- `main` - Production-ready code
- `develop` - Development branch for integration
- `feature/feature-name` - Feature branches
- `bugfix/bug-description` - Bug fix branches
- `hotfix/issue-description` - Hotfix branches

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the coding standards (see below)
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes**
   ```bash
   # Backend tests
   cd backend
   ./mvnw test
   
   # Frontend tests
   cd frontend
   npm test
   
   # Integration tests
   docker-compose up -d
   # Test the application manually
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new repository filtering feature
   
   - Add language-based filtering
   - Implement search by repository name
   - Update UI components for better UX
   
   Resolves #123"
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   # Create PR on GitHub
   ```

## Coding Standards

### Backend (Java/Spring Boot)

#### Code Style
- Use Java 21 features where appropriate
- Follow Spring Boot conventions
- Use meaningful variable and method names
- Add JavaDoc comments for public methods

#### Example:
```java
/**
 * Retrieves repository statistics from the cached data.
 * 
 * @return RepositoryStats containing aggregated statistics
 * @throws ServiceException if data retrieval fails
 */
@GetMapping("/stats")
public ResponseEntity<RepositoryStats> getRepositoryStats() {
    try {
        RepositoryStats stats = repositoryService.calculateStats();
        return ResponseEntity.ok(stats);
    } catch (Exception e) {
        log.error("Failed to retrieve repository statistics", e);
        throw new ServiceException("Statistics unavailable", e);
    }
}
```

#### Testing
- Write unit tests for service classes
- Use meaningful test method names
- Test both happy path and error cases

```java
@Test
void shouldReturnRepositoryStatsWhenDataExists() {
    // Given
    List<Repository> repositories = createTestRepositories();
    when(repositoryRepository.findAll()).thenReturn(repositories);
    
    // When
    RepositoryStats stats = repositoryService.calculateStats();
    
    // Then
    assertThat(stats.getTotalRepositories()).isEqualTo(5);
    assertThat(stats.getTotalStars()).isEqualTo(42);
}
```

### Frontend (React/TypeScript)

#### Code Style
- Use TypeScript strictly (no `any` types)
- Prefer functional components with hooks
- Use meaningful component and variable names
- Extract reusable logic into custom hooks

#### Example:
```typescript
interface RepositoryCardProps {
  repository: Repository;
  onSelect?: (repository: Repository) => void;
}

export const RepositoryCard: React.FC<RepositoryCardProps> = ({
  repository,
  onSelect
}) => {
  const handleClick = useCallback(() => {
    onSelect?.(repository);
  }, [repository, onSelect]);

  return (
    <Card 
      className="cursor-pointer hover:shadow-lg transition-shadow"
      onClick={handleClick}
    >
      <CardContent className="p-4">
        <h3 className="text-lg font-semibold">{repository.name}</h3>
        <p className="text-gray-600 text-sm">{repository.description}</p>
      </CardContent>
    </Card>
  );
};
```

#### Testing
- Write unit tests for components
- Test user interactions
- Mock API calls appropriately

```typescript
describe('RepositoryCard', () => {
  it('should call onSelect when clicked', () => {
    const mockRepository = createMockRepository();
    const mockOnSelect = jest.fn();

    render(
      <RepositoryCard 
        repository={mockRepository} 
        onSelect={mockOnSelect} 
      />
    );

    fireEvent.click(screen.getByRole('button'));
    expect(mockOnSelect).toHaveBeenCalledWith(mockRepository);
  });
});
```

## Types of Contributions

### 🐛 Bug Reports

When reporting bugs, please include:
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, browser, versions)
- Screenshots if applicable

**Bug Report Template:**
```markdown
## Bug Description
A clear description of what the bug is.

## Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. See error

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Environment
- OS: [e.g., macOS 13.0]
- Browser: [e.g., Chrome 108]
- Node.js: [e.g., 18.12.0]
- Java: [e.g., 21.0.1]

## Additional Context
Add any other context about the problem here.
```

### ✨ Feature Requests

For feature requests, please:
- Describe the problem you're trying to solve
- Explain your proposed solution
- Consider alternative solutions
- Provide mockups or examples if applicable

**Feature Request Template:**
```markdown
## Problem Statement
A clear description of the problem this feature would solve.

## Proposed Solution
Describe your proposed solution.

## Alternative Solutions
Describe any alternative solutions you've considered.

## Additional Context
Add any other context, mockups, or examples.
```

### 📝 Documentation

Documentation improvements are always welcome:
- Fix typos or grammatical errors
- Improve clarity and examples
- Add missing documentation
- Update outdated information

### 🚀 Features

When adding new features:
- Discuss the feature in an issue first
- Follow the existing architecture patterns
- Add comprehensive tests
- Update documentation
- Consider backward compatibility

## Pull Request Process

### PR Checklist

Before submitting a PR, ensure:
- [ ] Code follows project standards
- [ ] Tests are added and passing
- [ ] Documentation is updated
- [ ] Commit messages are clear
- [ ] PR description explains the changes
- [ ] No merge conflicts exist

### PR Template

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to break)
- [ ] Documentation update

## How Has This Been Tested?
Describe the tests you ran and how to reproduce them.

## Screenshots (if applicable)
Add screenshots to help explain your changes.

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review
- [ ] I have commented my code where necessary
- [ ] I have made corresponding changes to documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works
- [ ] New and existing tests pass locally
```

### Review Process

1. **Automated Checks**: CI/CD pipeline runs tests and security scans
2. **Code Review**: Maintainers review code for quality and standards
3. **Testing**: Manual testing of new features
4. **Merge**: Approved PRs are merged to develop, then main

## Release Process

### Semantic Versioning

We follow [Semantic Versioning](https://semver.org/):
- `MAJOR.MINOR.PATCH`
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Workflow

1. **Feature Development**: Features developed in feature branches
2. **Integration**: Features merged to `develop` branch
3. **Release Candidate**: Create release branch from `develop`
4. **Testing**: Comprehensive testing of release candidate
5. **Release**: Merge to `main` and tag version
6. **Deploy**: Automatic deployment to production

## Development Environment

### Local Development

#### Backend Only
```bash
cd backend
./mvnw spring-boot:run
# Backend available at http://localhost:8080
```

#### Frontend Only
```bash
cd frontend
npm install
npm start
# Frontend available at http://localhost:3000
```

#### Full Stack with Docker
```bash
docker-compose up -d
# Both services available with auto-restart
```

### Debugging

#### Backend Debugging
```bash
# Enable debug mode
cd backend
./mvnw spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005"
```

#### Frontend Debugging
- Use browser developer tools
- React Developer Tools extension
- Console logging for debugging

### Environment Variables

#### Development
```bash
# .env.development
GITHUB_TOKEN=your_development_token
NODE_ENV=development
REACT_APP_API_URL=http://localhost:8080
```

#### Testing
```bash
# .env.test
GITHUB_TOKEN=mock_token_for_tests
NODE_ENV=test
```

## Project Structure

### Backend Architecture
```
backend/
├── src/main/java/com/github/repodashboard/
│   ├── controller/     # REST API endpoints
│   ├── service/        # Business logic
│   ├── repository/     # Data access layer
│   ├── model/          # JPA entities
│   ├── dto/            # Data transfer objects
│   └── config/         # Configuration classes
├── src/main/resources/
│   └── application.properties
└── src/test/java/      # Unit and integration tests
```

### Frontend Architecture
```
frontend/
├── src/
│   ├── components/     # React components
│   │   └── ui/         # Base UI components
│   ├── hooks/          # Custom React hooks
│   ├── services/       # API communication
│   ├── types/          # TypeScript type definitions
│   └── utils/          # Utility functions
├── public/             # Static assets
└── tests/              # Unit and integration tests
```

## Communication

### Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Code Review**: For specific code feedback

### Communication Guidelines

- Be respectful and inclusive
- Provide clear and detailed information
- Use appropriate channels for different types of communication
- Be patient and helpful when assisting others

## Recognition

Contributors will be recognized in:
- `CONTRIBUTORS.md` file
- Release notes for significant contributions
- GitHub contributor statistics

## Questions?

If you have any questions about contributing, please:
1. Check existing issues and discussions
2. Create a new discussion on GitHub
3. Reach out to maintainers

Thank you for contributing to the GitHub Repository Dashboard! 🚀