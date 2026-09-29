#!/usr/bin/env bash
# Build from WSL, driving the Windows-side Connect IQ SDK.
#   ./build.sh                          bin/FishRegs.prg for the Descent G2 (sideload)
#   DEVICE=descentmk2 ./build.sh        same, for another product in manifest.xml (simulator testing)
#   ./build.sh store                    bin/FishRegs.iq, release build of every manifest product (store upload)
# Extra args pass through to monkeyc.
set -euo pipefail
cd "$(dirname "$0")"
SDK=$(tr -d '\r\n' < /mnt/c/Users/clamd/AppData/Roaming/Garmin/ConnectIQ/current-sdk.cfg)
KEY='C:\Users\clamd\Documents\devkeys\developer_key'
JAVA='/mnt/c/Program Files/Java/jdk-17/bin/java.exe'
BIN="$(wslpath -w "$PWD/bin")"
if [ "${1:-}" = store ]; then
    shift
    OUT=(-e -r -o "$BIN\\FishRegs.iq")
else
    OUT=(-o "$BIN\\FishRegs.prg" -d "${DEVICE:-descentg2}")
fi
python3 data/split.py      # regs.json -> per-group jsonData the watch loads one at a time
mkdir -p bin
"$JAVA" -Xms1g -Dfile.encoding=UTF-8 -jar "${SDK}bin\\monkeybrains.jar" \
    "${OUT[@]}" -f "$(wslpath -w "$PWD/monkey.jungle")" -y "$KEY" -w "$@"
