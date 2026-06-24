#!/usr/bin/env bash
# Compatibilidad: delega al servidor de desarrollo actual.
exec "$(cd "$(dirname "$0")" && pwd)/dev/start_dev.sh" "$@"
