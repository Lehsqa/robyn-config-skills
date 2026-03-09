#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
if ! command -v "${PYTHON_BIN}" >/dev/null 2>&1; then
  if command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
  else
    echo "Python is required but was not found in PATH." >&2
    exit 1
  fi
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is required but was not found in PATH." >&2
  exit 1
fi

INSTALLED_VERSION="$("${PYTHON_BIN}" - <<'PY'
from importlib.metadata import PackageNotFoundError, version

try:
    print(version("robyn-config"))
except PackageNotFoundError:
    print("not-installed")
PY
)"

LATEST_VERSION="$("${PYTHON_BIN}" - <<'PY'
import json
import urllib.request

with urllib.request.urlopen("https://pypi.org/pypi/robyn-config/json", timeout=10) as response:
    payload = json.load(response)

print(payload["info"]["version"])
PY
)"

if [[ "${INSTALLED_VERSION}" == "${LATEST_VERSION}" ]]; then
  echo "robyn-config is up to date (${INSTALLED_VERSION})."
  exit 0
fi

if [[ "${INSTALLED_VERSION}" == "not-installed" ]]; then
  echo "robyn-config is not installed. Installing ${LATEST_VERSION}..."
else
  echo "Updating robyn-config from ${INSTALLED_VERSION} to ${LATEST_VERSION}..."
fi

"${PYTHON_BIN}" -m pip install --upgrade robyn-config
npx skills update

echo "Update complete."
