#!/bin/sh
# Installs the Regolith themes into Herdr. Run it again to update them.
set -eu

REPO="https://raw.githubusercontent.com/Jmeza081/herdr-regolith/main/themes"
DEST="${HERDR_APP_HOME:-$HOME/.config/herdr-app}/themes"
THEMES="regolith regolith-dust regolith-orbit regolith-moss mono paper-cobalt"

mkdir -p "$DEST"
for name in $THEMES; do
  curl -fsSL "$REPO/$name.json" -o "$DEST/$name.json"
  echo "  installed $name"
done
echo "Done. Open Herdr's Settings (Cmd+,) > Look and pick a theme."
