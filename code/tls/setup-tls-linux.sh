#!/bin/bash
# TLS Certificate Setup for SQL Server on Linux
# This script automates TLS certificate configuration for
# SQL Server on Linux (including containers).
#
# For demo purposes, this creates a self-signed certificate.
# In production, use a CA-issued certificate.
#
# Run as root or with sudo on the SQL Server host.

set -e

# --- Configuration ---
CERT_SUBJECT="/CN=SQL Server TLS Certificate"
CERT_DIR="/etc/ssl/sqlserver"
CERT_FILE="$CERT_DIR/sqlserver.pem"
KEY_FILE="$CERT_DIR/sqlserver.key"
CERT_DAYS=730  # 2 years
MSSQL_CONF="/var/opt/mssql/mssql.conf"

echo "=== Step 1: Create certificate directory ==="
mkdir -p "$CERT_DIR"

echo "=== Step 2: Generate self-signed certificate ==="
openssl req -x509 -nodes \
    -newkey rsa:2048 \
    -subj "$CERT_SUBJECT" \
    -days "$CERT_DAYS" \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    2>/dev/null

echo "  Certificate: $CERT_FILE"
echo "  Private key: $KEY_FILE"

echo ""
echo "=== Step 3: Set ownership and permissions ==="
# SQL Server on Linux runs as the mssql user
chown mssql:mssql "$CERT_FILE" "$KEY_FILE"
chmod 600 "$KEY_FILE"
chmod 644 "$CERT_FILE"
echo "  Ownership set to mssql:mssql"

echo ""
echo "=== Step 4: Configure SQL Server to use the certificate ==="
# Use mssql-conf to set the TLS certificate and key
/opt/mssql/bin/mssql-conf set network.tlscert "$CERT_FILE"
/opt/mssql/bin/mssql-conf set network.tlskey "$KEY_FILE"
/opt/mssql/bin/mssql-conf set network.tlsprotocols 1.2,1.3
/opt/mssql/bin/mssql-conf set network.forceencryption 1

echo "  TLS settings written to $MSSQL_CONF"

echo ""
echo "=== Step 5: Restart SQL Server ==="
systemctl restart mssql-server 2>/dev/null || {
    echo "  systemctl not available (container?). Restart manually:"
    echo "    /opt/mssql/bin/sqlservr &"
    echo "  Or restart the container."
}

echo ""
echo "============================================"
echo "  TLS setup complete!"
echo "============================================"
echo ""
echo "To verify the encrypted connection, run:"
echo "  sqlcmd -S localhost -U sa -C -Q \\"
echo "    \"SELECT encrypt_option FROM sys.dm_exec_connections"
echo "     WHERE session_id = @@SPID;\""
echo ""
echo "For TLS 1.3 (SQL Server 2025), also check:"
echo "  SELECT protocol_version FROM sys.dm_exec_connections"
echo "  WHERE session_id = @@SPID;"
