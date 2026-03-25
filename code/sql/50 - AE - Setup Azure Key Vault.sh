#!/bin/bash
# Always Encrypted - Azure Key Vault Setup
# Run this script to create the Azure resources needed for
# Always Encrypted with AKV as the Column Master Key store.
#
# Prerequisites: az cli installed and logged in (az login)

set -e

# --- Configuration ---
RESOURCE_GROUP="rg-securesql-demo"
LOCATION="eastus"
VAULT_NAME="kv-securesql-$(openssl rand -hex 4)"
KEY_NAME="AlwaysEncryptedCMK"
APP_NAME="SecureSQLServerDemo"

echo "=== Creating Resource Group ==="
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

echo "=== Creating Key Vault: $VAULT_NAME ==="
az keyvault create \
    --name "$VAULT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --enable-rbac-authorization true \
    --output none

echo "=== Creating RSA Key (Column Master Key) ==="
az keyvault key create \
    --vault-name "$VAULT_NAME" \
    --name "$KEY_NAME" \
    --kty RSA \
    --size 2048 \
    --output none

KEY_URL=$(az keyvault key show \
    --vault-name "$VAULT_NAME" \
    --name "$KEY_NAME" \
    --query key.kid -o tsv)

echo "=== Creating App Registration ==="
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
az ad sp create --id "$APP_ID" --output none

echo "=== Creating Client Secret ==="
CLIENT_SECRET=$(az ad app credential reset \
    --id "$APP_ID" \
    --display-name "AE-Demo" \
    --query password -o tsv)

TENANT_ID=$(az account show --query tenantId -o tsv)

echo "=== Granting Key Vault Crypto User role ==="
VAULT_ID=$(az keyvault show --name "$VAULT_NAME" --query id -o tsv)
SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)

az role assignment create \
    --role "Key Vault Crypto User" \
    --assignee-object-id "$SP_OBJECT_ID" \
    --assignee-principal-type ServicePrincipal \
    --scope "$VAULT_ID" \
    --output none

echo "=== Granting current user Key Vault Crypto Officer role ==="
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
az role assignment create \
    --role "Key Vault Crypto Officer" \
    --assignee-object-id "$CURRENT_USER_ID" \
    --assignee-principal-type User \
    --scope "$VAULT_ID" \
    --output none

echo ""
echo "============================================"
echo "  Azure Key Vault setup complete!"
echo "============================================"
echo ""
echo "KEY_PATH for T-SQL CMK definition:"
echo "  $KEY_URL"
echo ""
echo "Connection parameters for SSMS/application:"
echo "  Tenant ID:     $TENANT_ID"
echo "  Client ID:     $APP_ID"
echo "  Client Secret: $CLIENT_SECRET"
echo "  Vault Name:    $VAULT_NAME"
echo ""
echo "Next steps:"
echo "  1. Update KEY_PATH in script 50 with the URL above"
echo "  2. Run 51 - AE - Provision Keys.ps1 to generate the CEK"
echo ""
echo "To clean up when done:"
echo "  az group delete --name $RESOURCE_GROUP --yes --no-wait"
