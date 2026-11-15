#!/usr/bin/env bash
set -euo pipefail

info() { printf '\033[1;34m[user-deps]\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m[user-deps]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[user-deps]\033[0m %s\n' "$*"; }

OS_NAME="$(uname -s)"

if [[ "${OS_NAME}" == "Darwin" ]]; then
	if ! command -v brew >/dev/null 2>&1; then
		warn "Homebrew not found; install Homebrew first: https://brew.sh"
		exit 1
	fi

	# 1. macOS IME switcher (used by lua/user/event.lua to auto-switch to ABC)
	if command -v im-select >/dev/null 2>&1 || command -v macism >/dev/null 2>&1; then
		ok "IME switcher already installed ($(command -v im-select || command -v macism))"
	else
		info "Installing im-select (daipeihust/tap/im-select)..."
		brew tap daipeihust/tap
		brew trust --formula daipeihust/tap/im-select
		brew install daipeihust/tap/im-select
		ok "im-select installed"
	fi
else
	info "Non-macOS (${OS_NAME}): skipping macOS-only im-select"
fi

# 2. Optional AI CLI tools used by lua/user/configs/codecompanion.lua
for tool in omp pi bun; do
	if command -v "${tool}" >/dev/null 2>&1; then
		ok "${tool}: $(command -v "${tool}")"
	else
		warn "${tool}: not found (optional)"
	fi
done

ok "Done."
