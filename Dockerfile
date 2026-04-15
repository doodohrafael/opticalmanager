FROM eclipse-temurin:25-jdk-alpine AS builder

WORKDIR /app

COPY pom.xml .
COPY .mvn/ .mvn/
COPY mvnw .

RUN ./mvnw dependency:go-offline -B

COPY src/ src/
RUN ./mvnw package -DskipTests --enable-preview -B

FROM eclipse-temurin:25-jre-alpine AS runtime

LABEL maintainer="opticalmanager"
LABEL description="Intelligent management system for optical stores with AI integration."
LABEL version="1.0.0-SNAPSHOT"

RUN addgroup -S opticalmanagergroup && adduser -S opticalmanageruser -G opticalmanagergroup
USER opticalmanageruser

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", \
    "-XX:+UseContainerSupport", \
    "-XX:MaxRAMPercentage=70.0", \
    "-XX:+OptimizeStringConcat", \
    "--enable-preview", \
    "-jar", "app.jar"]
