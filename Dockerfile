FROM maven:3.5.2-jdk-8-alpine AS MAVEN_BUILD
COPY pom.xml /build/
COPY src /build/src/

WORKDIR /build/
RUN ["mvn", "package", "-Dmaven.test.skip=true"]

FROM openjdk:11-jdk-slim
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
COPY --from=MAVEN_BUILD /build/target/k8sdemo-0.0.1-SNAPSHOT.jar app.jar
ENTRYPOINT ["java","-jar","/app.jar"]