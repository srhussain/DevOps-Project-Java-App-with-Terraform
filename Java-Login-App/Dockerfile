# Stage 1 — build the WAR with Maven + JDK 8
FROM maven:3-openjdk-8 AS build

WORKDIR /app

# Copy project files
COPY pom.xml .
COPY src/ ./src

# Build (skip tests if you like)
RUN mvn clean package -DskipTests

# Stage 2 — run with Tomcat 9 + JDK 8
FROM tomcat:9-jdk8-openjdk

# Remove default webapps (optional)
RUN rm -rf /usr/local/tomcat/webapps/ROOT* \
    && rm -rf /usr/local/tomcat/webapps/examples \
    && rm -rf /usr/local/tomcat/webapps/host-manager \
    && rm -rf /usr/local/tomcat/webapps/manager

# Copy built WAR
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
