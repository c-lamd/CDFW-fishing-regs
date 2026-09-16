#!/usr/bin/env bash
# Build bin/FishRegs.prg for the Descent G2 from WSL, driving the Windows-side Connect IQ SDK.
# Extra args pass through to monkeyc (e.g. ./build.sh --unit-test -o "$(wslpath -w "$PWD/bin")\\FishRegsTest.prg").
set -euo pipefail
cd "$(dirname "$0")"
SDK=$(tr -d '\r\n' < /mnt/c/Users/clamd/AppData/Roaming/Garmin/ConnectIQ/current-sdk.cfg)
KEY='C:\Users\clamd\Documents\devkeys\developer_key'
JAVA='/mnt/c/Program Files/Java/jdk-17/bin/java.exe'
mkdir -p bin
"$JAVA" -Xms1g -Dfile.encoding=UTF-8 -jar "${SDK}bin\\monkeybrains.jar" \
    -o "$(wslpath -w "$PWD/bin")\\FishRegs.prg" -f "$(wslpath -w "$PWD/monkey.jungle")" \
    -y "$KEY" -d descentg2 -w "$@"
