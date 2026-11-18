#!/bin/sh
# Installs the Regolith themes into Herdr. Run it again to update.
#   sh install.sh            themes only
#   sh install.sh --full    themes, plus the Regolith layout and its panels
set -eu

HOME_DIR="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL https://codeload.github.com/Jmeza081/herdr-regolith/tar.gz/refs/heads/main | tar -xz -C "$TMP"
SRC="$TMP/herdr-regolith-main"

mkdir -p "$HOME_DIR/themes"
cp "$SRC"/themes/*.json "$HOME_DIR/themes/"
echo "Installed the themes: $(cd "$SRC/themes" && ls | sed 's/\.json$//' | tr '\n' ' ')"

# The layout used to be named "regolith", like the theme. Herdr only offers a theme named
# like a layout inside that layout, so rename our old file to free the Regolith theme.
OLD="$HOME_DIR/layouts/regolith.json"
NEW="$HOME_DIR/layouts/regolith-layout.json"
if [ -f "$OLD" ] && grep -q '"regolith-chrome"' "$OLD"; then
  if [ -f "$NEW" ]; then mv "$OLD" "$OLD.old-$(date +%s)"; else mv "$OLD" "$NEW"; fi
  echo "Renamed the Regolith layout to regolith-layout, so the Regolith theme works in every layout."
fi

if [ "${1:-}" = "--full" ]; then
  mkdir -p "$HOME_DIR/layouts" "$HOME_DIR/mods"
  cp "$SRC/layouts/regolith-layout.json" "$HOME_DIR/layouts/"
  for mod in "$SRC"/mods/*/; do
    name="$(basename "$mod")"
    mkdir -p "$HOME_DIR/mods/$name"
    cp -R "$mod". "$HOME_DIR/mods/$name/"
  done
  # One-color program icons: only when there's no programs.json yet, so yours is never overwritten.
  if [ ! -f "$HOME_DIR/programs.json" ]; then
    cp "$SRC/programs.json" "$HOME_DIR/programs.json"
    echo "Program icons now draw in one color."
  else
    echo "Kept your programs.json. For one-color program icons, merge in $SRC/programs.json by hand."
  fi
  echo "Installed the Regolith layout and its panels."
  # If Herdr is open, switch to the layout and the Regolith theme now.
  if command -v herdr-app >/dev/null 2>&1 && herdr-app do layout.switch --name regolith-layout >/dev/null 2>&1; then
    herdr-app do app.theme --name regolith >/dev/null 2>&1 || true
    echo "Switched Herdr to the Regolith layout with the Regolith theme. Pick another theme any time in Settings (Cmd+,) > Look."
  else
    echo "Open Herdr, then pick Regolith Layout in Settings (Cmd+,) > Look > Layout, or run: herdr-app do layout.switch --name regolith-layout"
  fi
else
  echo "Open Herdr's Settings (Cmd+,) > Look and pick a theme."
fi
