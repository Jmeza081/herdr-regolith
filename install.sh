#!/bin/sh
# Installs the Regolith themes into Herdr. Run it again to update.
#   sh install.sh            themes only
#   sh install.sh --glass    themes, plus the Regolith Glass layout and its four panels
set -eu

HOME_DIR="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL https://codeload.github.com/Jmeza081/herdr-regolith/tar.gz/refs/heads/main | tar -xz -C "$TMP"
SRC="$TMP/herdr-regolith-main"

mkdir -p "$HOME_DIR/themes"
cp "$SRC"/themes/*.json "$HOME_DIR/themes/"
echo "Installed the themes: $(cd "$SRC/themes" && ls | sed 's/\.json$//' | tr '\n' ' ')"

if [ "${1:-}" = "--glass" ]; then
  mkdir -p "$HOME_DIR/layouts" "$HOME_DIR/mods"
  cp "$SRC/layouts/regolith-glass.json" "$HOME_DIR/layouts/"
  for mod in "$SRC"/mods/*/; do
    name="$(basename "$mod")"
    mkdir -p "$HOME_DIR/mods/$name"
    cp -R "$mod". "$HOME_DIR/mods/$name/"
  done
  echo "Installed the Regolith Glass layout and its panels."
  # If Herdr is open, switch to the layout and the Regolith theme now.
  if command -v herdr-app >/dev/null 2>&1 && herdr-app do layout.switch --name regolith-glass >/dev/null 2>&1; then
    herdr-app do app.theme --name regolith >/dev/null 2>&1 || true
    echo "Switched Herdr to Regolith Glass with the Regolith theme. Pick another theme any time in Settings (Cmd+,) > Look."
  else
    echo "Open Herdr, then pick Regolith Glass in Settings (Cmd+,) > Look > Layout, or run: herdr-app do layout.switch --name regolith-glass"
  fi
else
  echo "Open Herdr's Settings (Cmd+,) > Look and pick a theme."
fi
