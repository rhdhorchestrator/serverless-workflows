FROM registry.access.redhat.com/ubi9/openjdk-21:latest

USER root

WORKDIR /deployments

# Copy the pre-built quarkus application
COPY --chown=185:0 target/quarkus-app/lib/ /deployments/lib/
COPY --chown=185:0 target/quarkus-app/*.jar /deployments/
COPY --chown=185:0 target/quarkus-app/app/ /deployments/app/
COPY --chown=185:0 target/quarkus-app/quarkus/ /deployments/quarkus/

USER 185

ENV JAVA_APP_JAR="/deployments/quarkus-run.jar"

ENTRYPOINT ["java", "-jar", "quarkus-run.jar"]
