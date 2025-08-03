# Railway Backend Deployment - Spring Boot
FROM maven:3.9.6-eclipse-temurin-21 AS build

WORKDIR /app

# Copy backend pom.xml for better Docker layer caching
COPY backend/pom.xml .

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy backend source code
COPY backend/src ./src

# Build the application
RUN mvn clean package -DskipTests

# Use Java 21 runtime for running the application
FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy the built JAR from the build stage
COPY --from=build /app/target/*.jar app.jar

# Expose the port (Railway uses PORT environment variable)
EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:${PORT:-8080}/api/repos/stats || exit 1

# Run the application with Railway's PORT variable
CMD ["java", "-Dserver.port=${PORT:-8080}", "-jar", "app.jar"]