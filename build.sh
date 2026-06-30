#!/usr/bin/env bash
# Build machin-terminal. Uses the cached/vendored static raylib 5.0.
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"
SRC=term.src
APP=machin-terminal

RL_DIR="/tmp/rl/raylib-5.0_linux_amd64"
if [ ! -f "${RL_DIR}/lib/libraylib.a" ]; then
	echo "raylib not cached at ${RL_DIR}; vendoring..."
	mkdir -p /tmp/rl
	curl -fsSL "https://github.com/raysan5/raylib/releases/download/5.0/raylib-5.0_linux_amd64.tar.gz" | tar xz -C /tmp/rl
fi

"$MACHIN" encode "$SRC" > "${APP}.mfl"
"$MACHIN" build "${APP}.mfl" -o "$APP"
echo "built ./${APP} ($(ls -lh "$APP" | awk '{print $5}'))"
