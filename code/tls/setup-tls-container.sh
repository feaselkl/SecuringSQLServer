#!/bin/bash
# TLS Certificate Setup for SQL Server 2025 in a Rootless Container
#
# Runs on the HOST (not inside the container). It:
#   1. Generates a self-signed certificate on the host
#   2. Copies it into a running SQL Server container
#   3. Configures SQL Server to use it via mssql-conf
#   4. Restarts the container
#
# Designed for demos with podman (rootless) or docker.
#
# Usage:
#   ./setup-tls-container.sh [container-name]
#
# Example:
#   ./setup-tls-container.sh sql2025
#
# Optional environment variables:
#   CERT_DAYS      (default 730)
#   CERT_SUBJECT   (default "/CN=SQL Server TLS Certificate")
#   HOST_CERT_DIR  (default ./certs)

set -euo pipefail

CONTAINER="${1:-sql2025}"
CERT_DAYS="${CERT_DAYS:-730}"
CERT_SUBJECT="${CERT_SUBJECT:-/CN=SQL Server TLS Certificate}"
HOST_CERT_DIR="${HOST_CERT_DIR:-./certs}"
CONTAINER_CERT_DIR="/var/opt/mssql/certs"

# --- Detect container runtime ---
if command -v podman >/dev/null 2>&1; then
    RUNTIME=podman
elif command -v docker >/dev/null 2>&1; then
    RUNTIME=docker
else
    echo "Error: neither podman nor docker found on PATH" >&2
    exit 1
fi

command -v openssl >/dev/null 2>&1 || {
    echo "Error: openssl not found on PATH" >&2
    exit 1
}

echo "Runtime:   $RUNTIME"
echo "Container: $CONTAINER"

# --- Verify the container is running ---
if ! $RUNTIME ps --format '{{.Names}}' | grep -qw "$CONTAINER"; then
    echo ""
    echo "Error: container '$CONTAINER' is not running." >&2
    echo "Start one first, e.g.:" >&2
    echo "  $RUNTIME run -d --name $CONTAINER -p 1433:1433 \\" >&2
    echo "    -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD='<StrongPassword!>' \\" >&2
    echo "    mcr.microsoft.com/mssql/server:2025-latest" >&2
    exit 1
fi

echo ""
echo "=== Step 1: Generate self-signed certificate on host ==="
mkdir -p "$HOST_CERT_DIR"
HOST_CERT="$HOST_CERT_DIR/sqlserver.pem"
HOST_KEY="$HOST_CERT_DIR/sqlserver.key"

openssl req -x509 -nodes \
    -newkey rsa:2048 \
    -subj "$CERT_SUBJECT" \
    -days "$CERT_DAYS" \
    -keyout "$HOST_KEY" \
    -out "$HOST_CERT" \
    2>/dev/null
chmod 600 "$HOST_KEY"
echo "  Certificate: $HOST_CERT"
echo "  Private key: $HOST_KEY"

echo ""
echo "=== Step 2: Create cert directory inside container ==="
# Exec as UID 0 inside the container. For rootless podman/docker this maps
# to the host user via the user namespace, so no real root is involved.
$RUNTIME exec -u 0 "$CONTAINER" mkdir -p "$CONTAINER_CERT_DIR"

echo ""
echo "=== Step 3: Copy certificate into container ==="
$RUNTIME cp "$HOST_CERT" "$CONTAINER:$CONTAINER_CERT_DIR/sqlserver.pem"
$RUNTIME cp "$HOST_KEY"  "$CONTAINER:$CONTAINER_CERT_DIR/sqlserver.key"

echo ""
echo "=== Step 4: Set ownership and permissions inside container ==="
$RUNTIME exec -u 0 "$CONTAINER" chown mssql:root \
    "$CONTAINER_CERT_DIR/sqlserver.pem" \
    "$CONTAINER_CERT_DIR/sqlserver.key"
$RUNTIME exec -u 0 "$CONTAINER" chmod 600 "$CONTAINER_CERT_DIR/sqlserver.key"
$RUNTIME exec -u 0 "$CONTAINER" chmod 644 "$CONTAINER_CERT_DIR/sqlserver.pem"

echo ""
echo "=== Step 5: Configure SQL Server via mssql-conf ==="
$RUNTIME exec -u mssql "$CONTAINER" /opt/mssql/bin/mssql-conf set network.tlscert      "$CONTAINER_CERT_DIR/sqlserver.pem"
$RUNTIME exec -u mssql "$CONTAINER" /opt/mssql/bin/mssql-conf set network.tlskey       "$CONTAINER_CERT_DIR/sqlserver.key"
$RUNTIME exec -u mssql "$CONTAINER" /opt/mssql/bin/mssql-conf set network.tlsprotocols 1.2,1.3
$RUNTIME exec -u mssql "$CONTAINER" /opt/mssql/bin/mssql-conf set network.forceencryption 1

echo ""
echo "=== Step 6: Restart container to apply TLS settings ==="
$RUNTIME restart "$CONTAINER" >/dev/null
echo "  Restarted $CONTAINER"

cat <<EOF

============================================
  TLS setup complete!
============================================

Verify from inside the container:
  $RUNTIME exec -it $CONTAINER /opt/mssql-tools18/bin/sqlcmd \\
    -S localhost -U sa -C -Q \\
    "SELECT encrypt_option, protocol_version FROM sys.dm_exec_connections WHERE session_id = @@SPID;"

If mssql-tools18 is not installed in the image, connect from the host
with sqlcmd, SSMS, or Visual Studio Code and run the same query.
EOF
