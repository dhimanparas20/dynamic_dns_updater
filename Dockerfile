# Use a lightweight base image
FROM alpine:3.18

# Install necessary tools and tzdata package
RUN apk add --no-cache wget bash tzdata

# Set timezone
ENV TZ=Asia/Kolkata
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Create directories for logs and config
RUN mkdir -p /etc/freedns /var/log/freedns

# Copy the update script into the container
COPY update-script.sh /usr/local/bin/update-script.sh
RUN chmod +x /usr/local/bin/update-script.sh

# Set the command to run the script every hour with 12-hour time format
CMD echo "Container started at $(date '+%a %b %d %I:%M:%S %p %Z %Y')" && \
    sh -c "while true; do /usr/local/bin/update-script.sh; sleep 3600; done"
