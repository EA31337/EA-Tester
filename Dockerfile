# Set the base Ubuntu image.
FROM ubuntu:xenial AS ubuntu-base
ENV DEBIAN_FRONTEND noninteractive

# Setup the default user.
RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1001 ubuntu
USER ubuntu
WORKDIR /home/ubuntu

# Provision.
FROM ubuntu-base AS ubuntu-provisioned
USER root

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
COPY scripts /opt/scripts
ENV PATH $PATH:/opt/scripts:/opt/scripts/py
ENV PROVISION_HASH KwFCBBn659lGNLNiIGd5131XnknI
RUN provision.sh

# Clean up.
RUN find /var/lib/apt/lists -type f -delete && \
    find /tmp -mindepth 1 '(' -type d -o -type f ')' -delete

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

# Install MT4 platform.
FROM ea-tester-base AS ea-tester-with-mt4

# Install platform.
ARG MT_VER=4.0.0.1320
RUN eval.sh install_mt $MT_VER && \
    run_backtest.sh -s PrintPaths -v

# Clean up.
RUN eval.sh clean_bt && \
    eval.sh clean_ea && \
    eval.sh clean_files

# Install MT5 platform.
FROM ea-tester-base AS ea-tester-with-mt5

# Install platform.
ARG MT_VER=5.0.0.2361
ENV MT_VER $MT_VER
RUN eval.sh install_mt $MT_VER
#RUN run_backtest.sh -s PrintPaths -v

# Clean up.
#RUN eval.sh clean_bt
#RUN eval.sh clean_ea
#RUN eval.sh clean_files

# Final EA Tester image.
FROM ea-tester-with-mt4 as ea-tester

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

# Modify shell startup scripts.
RUN echo source /opt/scripts/.funcs.cmds.inc.sh >> ~/.bashrc

# Expose SSH and VNC when installed.
EXPOSE 22 5900

# Configure a container as an executable.
ENTRYPOINT ["eval.sh"]
