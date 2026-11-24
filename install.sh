#!/usr/bin/env bash
# Installe orm-pack dans ~/.local/bin (PREFIX pour changer)
set -euo pipefail
PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/orm-pack.sh"

if ! command -v magick >/dev/null 2>&1 && ! command -v convert >/dev/null 2>&1; then
  echo "✖ ImageMagick est requis :  sudo apt install imagemagick" >&2
  exit 1
fi
[[ -f "$SRC" ]] || { echo "✖ orm-pack.sh introuvable à côté de install.sh" >&2; exit 1; }

install -d "$BIN"
install -m 755 "$SRC" "$BIN/orm-pack"
echo "✔ Installé : $BIN/orm-pack"

case ":$PATH:" in
  *":$BIN:"*) echo "✔ Déjà dans le PATH. Essaie : orm-pack --help";;
  *) echo "⚠ Ajoute ceci à ton ~/.bashrc :"; echo "    export PATH=\"$BIN:\$PATH\"";;
esac
