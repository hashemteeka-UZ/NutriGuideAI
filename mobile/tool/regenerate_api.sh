#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
dart run swagger_parser
dart run build_runner build --delete-conflicting-outputs
dart run tool/gen_contract_examples_test.dart
