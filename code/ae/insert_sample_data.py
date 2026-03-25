"""Always Encrypted - Insert Sample Data via ODBC.

This script inserts sample patient records into the AETest database
using pyodbc with Always Encrypted enabled. It performs the same
inserts as script 53, but works on Linux where SSMS is not available.

Prerequisites:
  - ODBC Driver 18 for SQL Server installed
  - Azure Key Vault setup complete (script 51)
  - Column encryption keys provisioned (script 52)
  - Table created (script 53, Step 1 only - the CREATE TABLE)
  - .env file populated with connection and AKV credentials

Usage:
  uv run insert_sample_data.py
"""

import os
import sys
from datetime import date

import pyodbc
from dotenv import load_dotenv

load_dotenv()

SAMPLE_PATIENTS = [
    ("Alice", "Smith", "123-45-6789", "1985-03-15", "Annual checkup - all clear"),
    ("Bob", "Jones", "987-65-4321", "1990-07-22", "Follow-up on knee surgery"),
    (
        "Carol",
        "Williams",
        "555-12-3456",
        "1978-11-30",
        "Prescription renewal - blood pressure medication",
    ),
]


def get_env(key: str) -> str:
    value = os.getenv(key)
    if not value:
        print(f"Error: {key} is not set in .env", file=sys.stderr)
        sys.exit(1)
    return value


def main() -> None:
    server = get_env("SQL_SERVER")
    database = get_env("SQL_DATABASE")
    user = get_env("SQL_USER")
    password = get_env("SQL_PASSWORD")
    tenant_id = get_env("AKV_TENANT_ID")
    client_id = get_env("AKV_CLIENT_ID")
    client_secret = get_env("AKV_CLIENT_SECRET")

    conn_str = (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server={server};"
        f"Database={database};"
        f"UID={user};"
        f"PWD={password};"
        "ColumnEncryption=Enabled;"
        f"KeyStoreAuthentication=KeyVaultClientSecret;"
        f"KeyStorePrincipalId={client_id};"
        f"KeyStoreSecret={client_secret};"
        "TrustServerCertificate=Yes;"
    )

    print(f"Connecting to {server}/{database} with Always Encrypted enabled...")
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()

    insert_sql = (
        "INSERT INTO dbo.PatientRecords "
        "(FirstName, LastName, SSN, DateOfBirth, MedicalNotes) "
        "VALUES (?, ?, ?, ?, ?)"
    )

    # Always Encrypted requires exact SQL type matching.
    # pyodbc sends Python str as nvarchar by default, but SSN is char(11).
    cursor.setinputsizes([
        (pyodbc.SQL_WVARCHAR, 50, 0),   # FirstName  -> nvarchar(50)
        (pyodbc.SQL_WVARCHAR, 50, 0),   # LastName   -> nvarchar(50)
        (pyodbc.SQL_CHAR, 11, 0),        # SSN        -> char(11)
        (pyodbc.SQL_TYPE_DATE, 0, 0),    # DateOfBirth -> date
        (pyodbc.SQL_WVARCHAR, 0, 0),     # MedicalNotes -> nvarchar(max)
    ])

    for first, last, ssn, dob_str, notes in SAMPLE_PATIENTS:
        print(f"  Inserting {first} {last}...")
        dob = date.fromisoformat(dob_str)
        cursor.execute(insert_sql, first, last, ssn, dob, notes)

    conn.commit()
    cursor.close()
    conn.close()

    print(f"Inserted {len(SAMPLE_PATIENTS)} patient records.")


if __name__ == "__main__":
    main()
