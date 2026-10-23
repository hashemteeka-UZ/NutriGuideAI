$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
dart run swagger_parser
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
dart run tool/gen_contract_examples_test.dart
exit $LASTEXITCODE
