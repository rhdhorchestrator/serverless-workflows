#
# This Dockerfile adds Python support to the SonataFlow devmode image.
# 
# To build the image, run the following command:
# docker build -t sonataflow-devmode-python .
#
# To run the image with your workflow, run the following commands:
# IMAGE=sonataflow-devmode-python
# PATH_TO_WORKFLOW=<path-to-workflow-directory>
# docker run --ulimit nofile=262144:262144 -d --name sonataflow-devmode-python --add-host host.docker.internal:host-gateway -e QUARKUS_HTTP_PORT=8080 -p 8080:8080 -e KOGITO_SERVICE_URL=http://localhost:8080 -v $PATH_TO_WORKFLOW:/home/kogito/serverless-workflow-project/src/main/resources:Z -e KOGITO.CODEGEN.PROCESS.FAILONERROR=false -e QUARKUS_EMBEDDED_POSTGRESQL_DATA_DIR=/home/kogito/persistence -e QUARKUS_EXTENSIONS=org.apache.kie.sonataflow:sonataflow-addons-quarkus-python $IMAGE
#
#
#

FROM quay.io/kubesmarts/incubator-kie-sonataflow-devmode:1.36.0

USER root

# Install Python & build dependencies
RUN microdnf install -y \
    python3 \
    python3-devel \
    gcc \
    gcc-c++ \
    make \
    libffi-devel \
    && microdnf clean all

# Install JEP (compiles native lib)
RUN pip3 install --no-cache-dir jep

# Copy jep SO file to known location
RUN PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")') \
    && cp /usr/local/lib64/python${PY_VER}/site-packages/jep/libjep.so /usr/lib64

COPY --chown=185:185 path-to-your-python-scripts-folder /usr/local/lib64/python3.6/site-packages/my_scripts

USER 185
