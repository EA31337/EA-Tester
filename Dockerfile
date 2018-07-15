# Set the base image to Ubuntu
FROM ubuntu:xenial
MAINTAINER kenorb
ENV DEBIAN_FRONTEND noninteractive

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

# Setup the default user.
RUN useradd -d /home/ubuntu -ms /bin/bash -g root -G sudo -p ubuntu ubuntu
WORKDIR /home/ubuntu

# Provision container image,
ADD scripts /opt/scripts
ENV PATH $PATH:/opt/scripts
ENV PROVISION_SSH 1
ENV PROVISION_SUDO 1
ENV PROVISION_HASH KwFCBBn659lGNLNiIGd5131XnknI
RUN provision.sh

# Backtest input.
ENV BT_DEST /opt/results
ARG MT_VER=4.0.0.1010

# Run test.
USER ubuntu
ADD conf /opt/conf
ADD tests /opt/tests
RUN eval.sh install_mt 4

# Clean up.
USER root
RUN find /var/lib/apt/lists -type f -delete
RUN find /tmp -mindepth 1 '(' -type d -o -type f ')' -delete
USER ubuntu

# Share the results.
VOLUME /opt/results

# Expose SSH when installed.
EXPOSE 22

# Configure a container as an executable.
ENTRYPOINT ["eval.sh"]
