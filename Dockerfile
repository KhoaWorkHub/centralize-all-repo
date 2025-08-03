# Simplified Railway deployment - Backend only first
FROM maven:3.9.6-eclipse-temurin-21 AS build

WORKDIR /app

# Copy backend files
COPY backend/pom.xml .
RUN mvn dependency:go-offline -B

COPY backend/src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy the built jar
COPY --from=build /app/target/*.jar app.jar

# Expose port
EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8080}/api/repos/stats || exit 1

# Start command
CMD ["java", "-Dserver.port=${PORT:-8080}", "-jar", "app.jar"]