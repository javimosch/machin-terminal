#!/usr/bin/env bash
# Install machin-terminal from the latest GitHub release.
#
#   curl -fsSL https://raw.githubusercontent.com/javimosch/machin-terminal/master/install.sh | bash
#
# Downloads the prebuilt Linux x86_64 binary, installs it to a bin dir on PATH,
# checks runtime deps, and adds a desktop entry. Non-interactive / agent-friendly.
set -euo pipefail

REPO="javimosch/machin-terminal"
ASSET="machin-terminal-linux-x86_64"
URL="https://github.com/${REPO}/releases/latest/download/${ASSET}"

say() { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }

# --- platform check ---------------------------------------------------------
[ "$(uname -s)" = "Linux" ] || { say "machin-terminal ships a Linux build only (you have $(uname -s)). Build from source: https://github.com/${REPO}"; exit 1; }
[ "$(uname -m)" = "x86_64" ] || { say "no prebuilt binary for $(uname -m) yet — build from source: https://github.com/${REPO}"; exit 1; }
command -v curl >/dev/null || { say "curl is required."; exit 1; }

# --- pick an install dir on PATH --------------------------------------------
if echo ":${PATH}:" | grep -q ":${HOME}/.local/bin:"; then
	BINDIR="${HOME}/.local/bin"
else
	BINDIR="/usr/local/bin"
fi
mkdir -p "${BINDIR}" 2>/dev/null || true
DEST="${BINDIR}/machin-terminal"

# --- download + install -----------------------------------------------------
say "Downloading ${ASSET} → ${DEST}"
TMP="$(mktemp)"
curl -fSL "${URL}" -o "${TMP}"
chmod +x "${TMP}"
if [ -w "${BINDIR}" ]; then
	mv "${TMP}" "${DEST}"
else
	say "Need elevated permission to write ${BINDIR}…"
	sudo mv "${TMP}" "${DEST}"
fi

# --- runtime dependency checks (warnings only) ------------------------------
have() { ldconfig -p 2>/dev/null | grep -q "$1"; }
have 'libGL\.so'  || warn "libGL not found — install an OpenGL driver (e.g. 'sudo apt install libgl1 mesa-utils')."
have 'libX11\.so' || warn "libX11 not found — install X11 ('sudo apt install libx11-6'); on Wayland it runs via XWayland."
if ! fc-list 2>/dev/null | grep -qi mono; then
	warn "no monospace font found — 'sudo apt install fonts-dejavu-core'."
fi
fc-list 2>/dev/null | grep -qiE 'nerd|powerline|MesloLGS' || \
	say "tip: for Powerlevel10k icons, install a Nerd Font and run with MTERM_FONT=/path/to/NerdFont.ttf"

# --- desktop entry (so it shows in app launchers) ---------------------------
APPDIR="${HOME}/.local/share/applications"
mkdir -p "${APPDIR}"
cat > "${APPDIR}/machin-terminal.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=machin-terminal
Comment=A minimal terminal emulator in pure MFL
Exec=${DEST}
Terminal=false
Categories=System;TerminalEmulator;
EOF

# --- verify + next steps ----------------------------------------------------
say ""
say "Installed: $("${DEST}" --version)"
if echo ":${PATH}:" | grep -q ":${BINDIR}:"; then
	say "Run:  machin-terminal"
else
	say "Run:  ${DEST}"
	warn "${BINDIR} is not on your PATH — add it: echo 'export PATH=\"${BINDIR}:\$PATH\"' >> ~/.bashrc"
fi
say "Recommended: use with tmux + zsh/oh-my-zsh/powerlevel10k. See https://github.com/${REPO}"
