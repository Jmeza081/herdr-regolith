#!/bin/sh
# Installs the Regolith themes into Herdr. Run it again to update.
#   sh install.sh            themes only
#   sh install.sh --full    themes, plus the Regolith layout and its panels
#   sh install.sh --no-ring  themes, and no accent-colored outline on the focused pane in Herdr's own layout
set -eu

FULL=0
NO_RING=0
for arg in "$@"; do
  case "$arg" in
    --full) FULL=1 ;;
    --no-ring) NO_RING=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

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

if [ "$FULL" = 1 ]; then
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

# --no-ring: Herdr's own layout outlines the focused pane in the theme's accent, red in Regolith.
# The outline is one of the layout's saved clicks, so set it to the plain border color. layout.set
# replaces every saved click, so the ones already there (sizes, theme picks) are sent back with it.
if [ "$NO_RING" = 1 ]; then
  if [ "$FULL" = 1 ]; then
    echo "The Regolith layout already has no focus outline; --no-ring is for Herdr's own layout."
  elif ! command -v python3 >/dev/null 2>&1; then
    echo "--no-ring needs python3, which isn't installed. Nothing was changed."
  elif ! command -v herdr-app >/dev/null 2>&1 || ! STATUS="$(herdr-app status 2>/dev/null)"; then
    echo "--no-ring needs Herdr open. Open it and run this again."
  else
    STATE="$HOME_DIR/layouts/.state/main.json"
    # One copy of the clicks from before the first run; later runs leave it alone.
    BACKUP="$HOME_DIR/layouts/main.json.clicks-before-no-ring"
    MADE_BACKUP=0
    if [ -f "$STATE" ] && [ ! -f "$BACKUP" ]; then cp "$STATE" "$BACKUP"; MADE_BACKUP=1; fi
    if TREE="$(HERDR_STATUS="$STATUS" python3 - "$HOME_DIR" <<'PY'
import json, os, sys
home = sys.argv[1]
shown = json.loads(os.environ["HERDR_STATUS"]).get("layout")
if shown != "main":
    sys.stderr.write("--no-ring only changes Herdr's own layout (main); you're on \"%s\". Switch to it and run this again.\n" % shown)
    sys.exit(1)
tree = json.load(open(os.path.join(home, "layouts", "main.json")))
try:
    state = json.load(open(os.path.join(home, "layouts", ".state", "main.json")))
except FileNotFoundError:
    state = {}
clicks = state.get("nodes", {})

def merge(into, src):
    for key, value in src.items():
        if isinstance(value, dict) and isinstance(into.get(key), dict):
            merge(into[key], value)
        else:
            into[key] = value

def walk(node):
    click = dict(clicks.get(node.get("id"), {}))
    pane_click = click.pop("pane", None)
    merge(node, click)
    content = node.get("content")
    pane = content.get("pane") if isinstance(content, dict) else None
    if isinstance(pane, dict):
        if pane_click:
            height = pane_click.pop("header_height", None)
            if height is not None and isinstance(pane.get("header"), dict):
                pane["header"]["height"] = height
            merge(pane, pane_click)
        border = pane.get("border") or {"width": 1, "color": "border"}
        pane["focus"] = {"width": border.get("width", 1), "color": border.get("color", "border")}
    for child in node.get("children", []):
        walk(child)

walk(tree)
for key, value in state.items():
    if key not in ("nodes", "file"):
        tree[key] = value
print(json.dumps(tree))
PY
    )" && herdr-app do layout.set --layout "$TREE" >/dev/null 2>&1; then
      echo "Turned off the focus outline in Herdr's own layout."
      if [ -f "$BACKUP" ]; then echo "Your layout's saved sizes and theme picks were kept; a copy from before is at $BACKUP"; fi
    else
      if [ "$MADE_BACKUP" = 1 ]; then rm -f "$BACKUP"; fi
      echo "The focus outline was left as it was."
    fi
  fi
fi
