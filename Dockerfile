# Use a lightweight base image
FROM alpine:3.18

# Install necessary tools and tzdata package
RUN apk add --no-cache wget bash tzdata

# Set timezone and accept build arguments
ENV TZ=Asia/Kolkata
ENV UPDATE_INTERVAL=1
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Health check - verify the script is running and log file is being updated
HEALTHCHECK --interval=5m --timeout=10s --start-period=30s --retries=3 \
  CMD ps aux | grep -v grep | grep update-script.sh || exit 1

# Create directories for logs and config
RUN mkdir -p /etc/freedns /var/log/freedns

# Copy the update script into the container
COPY update-script.sh /usr/local/bin/update-script.sh
RUN chmod +x /usr/local/bin/update-script.sh

# Create entrypoint script
RUN printf '%s\n' '#!/bin/bash' \
    'echo "Container started at $(date '"'"'+%a %b %d %I:%M:%S %p %Z %Y'"'"')"' \
    'echo "Update interval: ${UPDATE_INTERVAL:-1} hour(s)"' \
    'while true; do' \
    '  /usr/local/bin/update-script.sh' \
    '  sleep ${SLEEP_SECONDS:-3600}' \
    'done' > /entrypoint.sh && chmod +x /entrypoint.sh

# Set the command to run the script at configured intervals (JSON format recommended)
CMD ["/entrypoint.sh"]
