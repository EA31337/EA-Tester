# Set the base image to Ubuntu
FROM ubuntu

# File Author / Maintainer
MAINTAINER kenorb

# Provision container image,
ADD "./scripts" "/opt"
ENTRYPOINT ["/opt/provision.sh"]
