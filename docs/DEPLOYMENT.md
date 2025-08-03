# Deployment Guide 🚀

This guide covers various deployment options for the GitHub Repository Dashboard, from free hosting solutions to production-ready setups.

## 🆓 Free Hosting Solutions

### 1. Railway (Recommended for Beginners)

Railway offers the easiest deployment experience with automatic Docker detection.

#### Features
- ✅ **Free Tier**: 500 hours/month (enough for small projects)
- ✅ **Auto-Deploy**: Connects to GitHub for automatic deployments
- ✅ **Managed Database**: PostgreSQL available
- ✅ **Custom Domains**: Free subdomain + custom domain support
- ✅ **Environment Variables**: Easy configuration via dashboard

#### Setup Steps

1. **Create Railway Account**: Visit [railway.app](https://railway.app)

2. **Install Railway CLI**:
```bash
npm install -g @railway/cli
```

3. **Login and Deploy**:
```bash
# Login to Railway
railway login

# In your project directory
railway link
railway up
```

4. **Configure Environment Variables**:
   - Go to Railway dashboard
   - Add `GITHUB_TOKEN` environment variable
   - Railway will automatically build using Docker

5. **Custom Domain** (Optional):
   - Go to Settings > Domains
   - Add your custom domain or use Railway's provided domain

#### Railway Configuration File
Create `railway.toml` in your project root:

```toml
[build]
buildCommand = "docker-compose build"
startCommand = "docker-compose up"

[deploy]
healthcheckPath = "/api/repos/stats"
healthcheckTimeout = 300
restartPolicyType = "always"
```

### 2. Render

Render provides excellent free tier with automatic SSL and global CDN.

#### Features
- ✅ **Free Tier**: 750 hours/month for web services
- ✅ **Auto-Deploy**: GitHub integration
- ✅ **Free SSL**: Automatic HTTPS certificates
- ✅ **Global CDN**: Fast content delivery
- ✅ **PostgreSQL**: Free managed database (90 days)

#### Setup Steps

1. **Create Render Account**: Visit [render.com](https://render.com)

2. **Create Web Service**:
   - Connect your GitHub repository
   - Choose "Docker" as environment
   - Set build command: `docker-compose build`
   - Set start command: `docker-compose up`

3. **Environment Variables**:
   - Add `GITHUB_TOKEN` in Render dashboard
   - Add `NODE_ENV=production`

4. **Database Setup** (Optional):
   - Create PostgreSQL database on Render
   - Update Spring Boot configuration

#### Render Configuration
Create `render.yaml`:

```yaml
services:
  - type: web
    name: github-repo-dashboard
    env: docker
    dockerfilePath: ./Dockerfile
    buildCommand: docker-compose build
    startCommand: docker-compose up
    envVars:
      - key: GITHUB_TOKEN
        sync: false
      - key: NODE_ENV
        value: production
    healthCheckPath: /api/repos/stats
```

### 3. Fly.io

Great for global deployment with edge locations.

#### Features
- ✅ **Free Tier**: $5 credit monthly
- ✅ **Global Deployment**: Multiple regions
- ✅ **Auto-scaling**: Scale based on demand
- ✅ **PostgreSQL**: Free managed database

#### Setup Steps

1. **Install Fly CLI**:
```bash
# macOS
brew install flyctl

# Linux/Windows
curl -L https://fly.io/install.sh | sh
```

2. **Login and Deploy**:
```bash
fly auth login
fly launch
```

3. **Configuration**:
```bash
# Set environment variables
fly secrets set GITHUB_TOKEN=your_token_here
```

### 4. Google Cloud Run

Perfect for serverless container deployment.

#### Features
- ✅ **Free Tier**: 2 million requests/month
- ✅ **Auto-scaling**: Scale to zero when not used
- ✅ **Global**: Multiple regions available
- ✅ **Integration**: Works with Google Cloud services

#### Setup Steps

1. **Install Google Cloud SDK**
2. **Build and Deploy**:
```bash
# Build for production
docker build -t gcr.io/YOUR_PROJECT_ID/github-repo-dashboard .

# Push to Google Container Registry
docker push gcr.io/YOUR_PROJECT_ID/github-repo-dashboard

# Deploy to Cloud Run
gcloud run deploy github-repo-dashboard \
  --image gcr.io/YOUR_PROJECT_ID/github-repo-dashboard \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

## 💰 Low-Cost VPS Options

### DigitalOcean Droplet ($5/month)

#### Setup Steps

1. **Create Droplet**:
   - Choose Ubuntu 22.04 LTS
   - $5/month basic droplet
   - Add SSH key

2. **Server Setup**:
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Clone your repository
git clone https://github.com/yourusername/github-repo-dashboard.git
cd github-repo-dashboard

# Set environment variables
echo "GITHUB_TOKEN=your_token_here" > .env

# Start application
./start.sh
```

3. **Setup Domain & SSL**:
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d yourdomain.com
```

### Linode ($5/month)

Similar setup to DigitalOcean:

1. Create Linode instance
2. Follow same Docker setup steps
3. Configure domain and SSL

## 🏢 Production Deployment

### AWS ECS with Fargate

For production-grade deployment with high availability.

#### Architecture
- **ECS Fargate**: Serverless container deployment
- **Application Load Balancer**: High availability
- **RDS PostgreSQL**: Managed database
- **CloudFront**: Global CDN
- **Route 53**: DNS management

#### Setup with Terraform

Create `infrastructure/main.tf`:

```hcl
provider "aws" {
  region = "us-east-1"
}

# ECS Cluster
resource "aws_ecs_cluster" "github_dashboard" {
  name = "github-dashboard"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "github-dashboard"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "your-ecr-repo/github-dashboard-backend:latest"
      
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "GITHUB_TOKEN"
          value = var.github_token
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/github-dashboard"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "github-dashboard"
  cluster         = aws_ecs_cluster.github_dashboard.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "backend"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.app]
}
```

#### Deployment Commands

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply

# Build and push Docker images
docker build -t your-ecr-repo/github-dashboard-backend:latest ./backend
docker push your-ecr-repo/github-dashboard-backend:latest

# Update ECS service
aws ecs update-service --cluster github-dashboard --service github-dashboard --force-new-deployment
```

### Kubernetes (GKE/EKS/AKS)

For enterprise-grade deployment with Kubernetes.

#### Kubernetes Manifests

Create `k8s/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: github-dashboard-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: github-dashboard-backend
  template:
    metadata:
      labels:
        app: github-dashboard-backend
    spec:
      containers:
      - name: backend
        image: your-registry/github-dashboard-backend:latest
        ports:
        - containerPort: 8080
        env:
        - name: GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: github-dashboard-secrets
              key: github-token
        livenessProbe:
          httpGet:
            path: /api/repos/stats
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/repos/stats
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: github-dashboard-service
spec:
  selector:
    app: github-dashboard-backend
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
```

#### Deployment Commands

```bash
# Create namespace
kubectl create namespace github-dashboard

# Create secret
kubectl create secret generic github-dashboard-secrets \
  --from-literal=github-token='your_token_here' \
  -n github-dashboard

# Deploy application
kubectl apply -f k8s/ -n github-dashboard

# Get external IP
kubectl get service github-dashboard-service -n github-dashboard
```

## 🔄 CI/CD Pipeline

### GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 21
      uses: actions/setup-java@v3
      with:
        java-version: '21'
        distribution: 'temurin'
    
    - name: Run backend tests
      run: |
        cd backend
        ./mvnw test
    
    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: frontend/package-lock.json
    
    - name: Run frontend tests
      run: |
        cd frontend
        npm ci
        npm test

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to Railway
      uses: railwayapp/cli@v2
      with:
        command: up
      env:
        RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

## 🔧 Environment-Specific Configurations

### Development
```bash
NODE_ENV=development
GITHUB_TOKEN=your_dev_token
SPRING_PROFILES_ACTIVE=dev
```

### Staging
```bash
NODE_ENV=staging
GITHUB_TOKEN=your_staging_token
SPRING_PROFILES_ACTIVE=staging
DATABASE_URL=postgresql://staging-db-url
```

### Production
```bash
NODE_ENV=production
GITHUB_TOKEN=your_prod_token
SPRING_PROFILES_ACTIVE=production
DATABASE_URL=postgresql://production-db-url
REDIS_URL=redis://production-redis-url
```

## 📊 Monitoring & Observability

### Health Checks

The application includes built-in health check endpoints:

- **Backend Health**: `GET /api/repos/stats`
- **Application Status**: Returns 200 if GitHub API is accessible
- **Database Status**: H2 database connectivity

### Logging

#### Application Logs
```bash
# View Docker logs
docker logs github-repo-backend --follow

# View specific service logs
docker-compose logs -f backend
```

#### Production Logging
- **CloudWatch** (AWS)
- **Stackdriver** (Google Cloud)
- **Application Insights** (Azure)

### Metrics

Set up monitoring with:
- **Prometheus + Grafana**
- **DataDog**
- **New Relic**

## 🛡️ Security Considerations

### Environment Variables
- Never commit `.env` files
- Use secret management services in production
- Rotate GitHub tokens regularly

### Network Security
- Use HTTPS in production
- Configure CORS properly
- Implement rate limiting

### Container Security
- Use non-root users in containers
- Scan images for vulnerabilities
- Keep dependencies updated

## 🆘 Troubleshooting

### Common Deployment Issues

#### 1. GitHub Token Issues
```bash
# Test token validity
curl -H "Authorization: Bearer YOUR_TOKEN" https://api.github.com/user
```

#### 2. Memory Issues
```bash
# Increase container memory
docker-compose up --scale backend=1 --memory=2g
```

#### 3. Port Conflicts
```bash
# Check port usage
lsof -i :8080
lsof -i :3000
```

#### 4. Database Connection Issues
```bash
# Check H2 console
# Visit: http://localhost:8080/h2-console
# JDBC URL: jdbc:h2:mem:testdb
```

---

Choose the deployment option that best fits your needs and budget. Start with free options like Railway or Render for development and small projects, then move to VPS or cloud solutions as you scale.