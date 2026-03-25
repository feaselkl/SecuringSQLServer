FROM mcr.microsoft.com/mssql/server:2025-latest

# Create directories for demo scripts inside the container
RUN mkdir -p /var/opt/mssql/scripts/sql /var/opt/mssql/scripts/tls

# Copy demo scripts into the container
COPY sql/ /var/opt/mssql/scripts/sql/
COPY tls/ /var/opt/mssql/scripts/tls/

# Ensure the mssql user can read the scripts
RUN chown -R mssql:root /var/opt/mssql/scripts && \
    chmod -R 0550 /var/opt/mssql/scripts

EXPOSE 1433

# Use the default entrypoint from the base image
