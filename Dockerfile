# Use a lightweight base image
FROM alpine:3.18

# Install necessary tools
RUN apk add --no-cache wget bash

# Create directories for logs and config
RUN mkdir -p /etc/freedns /var/log/freedns

# Copy the update script into the container
COPY update-script.sh /usr/local/bin/update-script.sh
RUN chmod +x /usr/local/bin/update-script.sh

# Set the command to run the script every hour
CMD echo "Container started at $(date)" && sh -c "while true; do /usr/local/bin/update-script.sh; sleep 3600; done"
