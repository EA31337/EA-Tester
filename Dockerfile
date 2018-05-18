# Set the base image to Ubuntu
FROM ubuntu:xenial
MAINTAINER kenorb
ENV DEBIAN_FRONTEND noninteractive

# Setup default user.
RUN useradd -d /home/ubuntu -ms /bin/bash -g root -G sudo -p ubuntu ubuntu
WORKDIR /home/ubuntu

# Provision container image,
ADD scripts /opt/scripts
ENV PATH $PATH:/opt/scripts
RUN provision.sh

# Backtest input.
ENV DEST /opt/results
ARG YEARS
ENV YEARS ${YEAR:-2017}

# Run test.
USER ubuntu
ADD conf /opt/conf
ADD tests /opt/tests
RUN run_backtest.sh -v -t -M4.0.0.1010 -d 2000 -p EURUSD -m 1 -s 10 -b DS -D5 -e TestTimeframes -P M30
RUN eval.sh clean_files
RUN eval.sh clean_bt

# Share the results.
VOLUME /opt/results

# Configure a container as an executable.
ENTRYPOINT ["run_backtest.sh"]
