# Builds the site into _site/: inlines the theme colors into index.html and copies the theme files.
import json, glob, os, shutil
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = os.path.join(root, "_site")
shutil.rmtree(out, ignore_errors=True)
shutil.copytree(os.path.join(root, "site"), out, ignore=shutil.ignore_patterns("build.py"))
shutil.copytree(os.path.join(root, "themes"), os.path.join(out, "themes"))
themes = {}
for f in sorted(glob.glob(os.path.join(root, "themes", "*.json"))):
    d = json.load(open(f))
    c = {k: v[:7] for k, v in d["colors"].items()}  # the preview draws solid colors; glass alpha is for Herdr
    c.update(background=d["background"], foreground=d["foreground"], ansi=d["ansi"])
    themes[os.path.basename(f)[:-5]] = c
p = os.path.join(out, "index.html")
html = open(p).read()
assert "/*THEMES*/" in html
open(p, "w").write(html.replace("/*THEMES*/", json.dumps(themes)))
print("built", out)
