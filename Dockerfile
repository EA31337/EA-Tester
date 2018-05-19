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
ENV BT_DEST /opt/results
ARG BOOT_CODE
ARG FINAL_CODE
ARG BT_START_DATE
ARG BT_END_DATE
ENV BT_START_DATE ${BT_START_DATE:-2017.01.01}
ARG BT_YEARS
ENV BT_YEARS ${BT_YEARS:-2017}
ARG BT_MONTHS
ENV BT_MONTHS ${BT_MONTHS:-1}

# Run test.
USER ubuntu
ADD conf /opt/conf
ADD tests /opt/tests
RUN run_backtest.sh -v -t -M4.0.0.1010 -d 2000 -p EURUSD -m 1 -s 10 -b DS -D5 -e TestTimeframes -P M30
RUN eval.sh (clean_files && clean_bt)

# Share the results.
VOLUME /opt/results

# Configure a container as an executable.
ENTRYPOINT ["eval.sh"]
