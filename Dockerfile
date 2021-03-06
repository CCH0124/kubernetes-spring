FROM maven:3.8.4-jdk-11 AS MAVEN_BUILD
COPY pom.xml /build/
COPY src /build/src/

WORKDIR /build/
RUN ["mvn", "package", "-Dmaven.test.skip=true"]

FROM adoptopenjdk/openjdk11:alpine-jre 
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
ARG HASH
ARG LOG
ENV COMMITHASH=$HASH
ENV COMMITLOG=$LOG
COPY --from=MAVEN_BUILD /build/target/k8sdemo-0.0.1-SNAPSHOT.jar app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
