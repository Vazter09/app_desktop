#!/usr/bin/env bash
# Delega al instalador canónico en database/
exec "$(cd "$(dirname "$0")/../.." && pwd)/database/setup_smartcset.sh" "$@"
