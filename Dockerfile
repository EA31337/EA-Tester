# Set the base Ubuntu image.
FROM ubuntu:jammy AS ubuntu-base
ENV DEBIAN_FRONTEND noninteractive

# Setup the default user.
RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1001 ubuntu
USER ubuntu
WORKDIR /home/ubuntu

# Provision.
FROM ubuntu-base AS ubuntu-provisioned
USER root

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="EA-Tester" \
      org.label-schema.description="Headless Forex backtesting for MetaTrader platform" \
      org.label-schema.url="https://github.com/EA31337/EA-Tester" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/EA31337/EA-Tester" \
      org.label-schema.vendor="FX31337" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

# Build-time variables.
ARG HTTPS_PROXY
ARG HTTP_PROXY
ARG PROVISION_AHK=0
ARG PROVISION_CHARLES=0
ARG PROVISION_MONO=0
ARG PROVISION_SSH=0
ARG PROVISION_SUDO=1
ARG PROVISION_VNC=1

# Provision container image.
COPY ansible /opt/ansible
COPY scripts /opt/scripts
ENV PATH $PATH:/opt/scripts:/opt/scripts/py
RUN provision.sh

# Uses ubuntu as default user.
USER ubuntu

# Setup EA Tester base image.
FROM ubuntu-provisioned AS ea-tester-base

# Add files.
COPY conf /opt/conf
COPY tests /opt/tests

# Setup results directory.
ARG BT_DEST=/opt/results
ENV BT_DEST $BT_DEST
RUN mkdir -v -m a=rwx $BT_DEST && \
    chown ubuntu:root $BT_DEST
VOLUME $BT_DEST

# Expose SSH and VNC when installed.
EXPOSE 22 5900

# Configure a container as an executable.
ENTRYPOINT ["eval.sh"]
