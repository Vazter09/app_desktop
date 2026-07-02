#!/usr/bin/env bash
cd "$(dirname "$0")"
set -a; source .env.local; set +a
.venv/bin/python motor_biometrico.py
