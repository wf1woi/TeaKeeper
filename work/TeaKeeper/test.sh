#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TEST_DIRECTORY="$(mktemp -d)"
TEST_BINARY="$TEST_DIRECTORY/TeaKeeperTests"
trap 'rm -rf "$TEST_DIRECTORY"' EXIT

swiftc \
  -target arm64-apple-macosx13.0 \
  "$ROOT/Sources/PowerController.swift" \
  "$ROOT/Sources/DisplaySleepPolicy.swift" \
  "$ROOT/Sources/Localization.swift" \
  "$ROOT/Sources/DebugLog.swift" \
  "$ROOT/Tests/main.swift" \
  -framework IOKit \
  -o "$TEST_BINARY"

TEAKEEPER_TESTING=1 "$TEST_BINARY"
