"""Always Encrypted - Query Encrypted Data via ODBC.

This script demonstrates how Always Encrypted behaves from different
connection contexts, mirroring the tests in script 54.

Test 1: Query WITHOUT Always Encrypted — returns binary ciphertext.
Test 2: Query WITH Always Encrypted — returns plaintext via AKV decryption.
Test 3: Parameterized equality lookup on a deterministic column.

Prerequisites:
  - ODBC Driver 18 for SQL Server installed
  - Sample data inserted (insert_sample_data.py or script 53)
  - .env file populated with connection and AKV credentials

Usage:
  uv run query_encrypted_data.py
"""

import os
import sys

import pyodbc
from dotenv import load_dotenv

load_dotenv()

SEPARATOR = "-" * 60


def get_env(key: str) -> str:
    value = os.getenv(key)
    if not value:
        print(f"Error: {key} is not set in .env", file=sys.stderr)
        sys.exit(1)
    return value


def print_rows(cursor: pyodbc.Cursor) -> None:
    columns = [desc[0] for desc in cursor.description]
    rows = cursor.fetchall()
    if not rows:
        print("  (no rows returned)")
        return

    # Calculate column widths
    widths = [len(c) for c in columns]
    str_rows = []
    for row in rows:
        str_row = []
        for i, val in enumerate(row):
            if isinstance(val, bytes):
                s = f"0x{val[:16].hex()}..." if len(val) > 16 else f"0x{val.hex()}"
            else:
                s = str(val) if val is not None else "NULL"
            str_row.append(s)
            widths[i] = max(widths[i], len(s))
        str_rows.append(str_row)

    # Print header
    header = " | ".join(c.ljust(w) for c, w in zip(columns, widths))
    print(f"  {header}")
    print(f"  {'-+-'.join('-' * w for w in widths)}")
    for str_row in str_rows:
        line = " | ".join(v.ljust(w) for v, w in zip(str_row, widths))
        print(f"  {line}")
    print(f"  ({len(rows)} row(s))")


def base_conn_str() -> str:
    server = get_env("SQL_SERVER")
    database = get_env("SQL_DATABASE")
    user = get_env("SQL_USER")
    password = get_env("SQL_PASSWORD")
    return (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server={server};"
        f"Database={database};"
        f"UID={user};"
        f"PWD={password};"
        "TrustServerCertificate=Yes;"
    )


def ae_conn_str() -> str:
    client_id = get_env("AKV_CLIENT_ID")
    client_secret = get_env("AKV_CLIENT_SECRET")
    return (
        base_conn_str()
        + "ColumnEncryption=Enabled;"
        f"KeyStoreAuthentication=KeyVaultClientSecret;"
        f"KeyStorePrincipalId={client_id};"
        f"KeyStoreSecret={client_secret};"
    )


SELECT_ALL = (
    "SELECT PatientId, FirstName, LastName, SSN, DateOfBirth, MedicalNotes "
    "FROM dbo.PatientRecords"
)


def test1_without_ae() -> None:
    print(SEPARATOR)
    print("Test 1: Query WITHOUT Always Encrypted")
    print("  Encrypted columns appear as binary ciphertext.")
    print(SEPARATOR)
    conn = pyodbc.connect(base_conn_str())
    cursor = conn.cursor()
    cursor.execute(SELECT_ALL)
    print_rows(cursor)
    conn.close()
    print()


def test2_with_ae() -> None:
    print(SEPARATOR)
    print("Test 2: Query WITH Always Encrypted")
    print("  ODBC driver decrypts via Azure Key Vault — plaintext values.")
    print(SEPARATOR)
    conn = pyodbc.connect(ae_conn_str())
    cursor = conn.cursor()
    cursor.execute(SELECT_ALL)
    print_rows(cursor)
    conn.close()
    print()


def test3_parameterized_lookup() -> None:
    print(SEPARATOR)
    print("Test 3: Parameterized equality lookup on SSN (deterministic)")
    print("  Searching for SSN = '123-45-6789'")
    print(SEPARATOR)
    conn = pyodbc.connect(ae_conn_str())
    cursor = conn.cursor()
    cursor.setinputsizes([(pyodbc.SQL_CHAR, 11, 0)])
    cursor.execute(
        "SELECT PatientId, FirstName, LastName, SSN, DateOfBirth "
        "FROM dbo.PatientRecords WHERE SSN = ?",
        "123-45-6789",
    )
    print_rows(cursor)
    conn.close()
    print()


def main() -> None:
    print()
    print("Always Encrypted - Query Demo")
    print("=" * 60)
    print()

    test1_without_ae()
    test2_with_ae()
    test3_parameterized_lookup()

    print(SEPARATOR)
    print("Key takeaway:")
    print("  Without secure enclaves, Always Encrypted supports only")
    print("  equality comparisons on deterministically encrypted columns,")
    print("  and no query operations on randomly encrypted columns.")
    print("  LIKE and range queries will fail (see script 54 for details).")
    print(SEPARATOR)


if __name__ == "__main__":
    main()
