# Set the base Ubuntu image.
FROM ubuntu:xenial AS ubuntu-base
MAINTAINER kenorb
ENV DEBIAN_FRONTEND noninteractive

# Setup the default user.
RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1000 ubuntu
WORKDIR /home/ubuntu

# Provision.
FROM ubuntu-base AS ea-tester-provisioned

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
ADD scripts /opt/scripts
ENV PATH $PATH:/opt/scripts:/opt/scripts/py
ENV PROVISION_HASH KwFCBBn659lGNLNiIGd5131XnknI
RUN provision.sh

# Install MT platform.
FROM ea-tester-provisioned AS ea-tester-with-mt4

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="EA-Tester" \
      org.label-schema.description="Headless backtesting for MT4 platform" \
      org.label-schema.url="https://github.com/EA31337/EA-Tester" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/EA31337/EA-Tester" \
      org.label-schema.vendor="FX31337" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

# Setup results directory.
ARG BT_DEST=/opt/results
ENV BT_DEST $BT_DEST
RUN mkdir -v -m a=rwx $BT_DEST
RUN chown ubuntu:root $BT_DEST
VOLUME $BT_DEST

# Default backtest inputs.
ARG MT_VER=4.0.0.1260
ENV MT_VER $MT_VER

# Run test.
USER ubuntu
ADD conf /opt/conf
ADD tests /opt/tests
RUN eval.sh install_mt $MT_VER
RUN run_backtest.sh -s PrintPaths -v

# Clean up.
USER root
RUN find /var/lib/apt/lists -type f -delete
RUN find /tmp -mindepth 1 '(' -type d -o -type f ')' -delete
USER ubuntu
RUN eval.sh clean_bt
RUN eval.sh clean_ea
RUN eval.sh clean_files

# Expose SSH and VNC when installed.
EXPOSE 22 5900

# Modify shell startup scripts.
RUN echo source /opt/scripts/.funcs.cmds.inc.sh >> ~/.bashrc

# Configure a container as an executable.
ENTRYPOINT ["eval.sh"]
