# Set the base image to Ubuntu
FROM ubuntu:xenial
MAINTAINER kenorb
ENV DEBIAN_FRONTEND noninteractive

# Provision container image,
ADD "./scripts" "/opt/scripts"
RUN "/opt/scripts/provision.sh"

# Setup ubuntu user.
RUN useradd -d /home/ubuntu -ms /bin/bash -g root -G sudo -p ubuntu ubuntu
USER ubuntu
WORKDIR /home/ubuntu

CMD ["/bin/bash"]
#CMD ["/opt/provision.sh"]
