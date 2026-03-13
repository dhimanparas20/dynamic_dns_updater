# Use a lightweight base image
FROM alpine:3.21

# Install runtime dependencies
RUN apk add --no-cache bash curl wget ca-certificates tzdata

ENV TZ=UTC
ENV UPDATE_INTERVAL=1
ENV LOG_FILE=/var/log/freedns/dnsactual.log

# Create directories for state and logs
RUN mkdir -p /etc/freedns /var/log/freedns /var/run/freedns

# Copy scripts into the container
COPY update-script.sh /usr/local/bin/update-script.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/update-script.sh /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh

# Healthcheck validates periodic attempts and recent successful runs.
HEALTHCHECK --interval=5m --timeout=10s --start-period=90s --retries=3 \
  CMD /usr/local/bin/healthcheck.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
