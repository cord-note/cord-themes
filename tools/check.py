"""Checks every theme in themes/ before it can be merged. Run: python tools/check.py

A theme passes when:
- its folder holds theme.css and theme.json, and the folder name is the theme id
- every CSS rule is scoped to [data-theme="<id>"], the way Cord's loader requires
- it only uses @media, @supports, @font-face and @keyframes, and no remote url()
- it sets every colour token for the dark scheme (the light scheme may inherit)
- text, links and the accent meet their contrast targets in both schemes
- theme.json has a name, description, author, tags and palette swatches
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from colour import CONTRAST, TOKENS, contrast, parse_blocks  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), '..')
BUILTIN = {'mono', 'blue', 'olive', 'teal', 'midnight', 'rosewood', 'parchment'}
ID = re.compile(r'^[a-z0-9][a-z0-9-]{0,63}$')
HEX = re.compile(r'^#[0-9a-f]{6}$')
ALLOWED_AT = {'media', 'supports', 'font-face', 'keyframes'}
GROUPS = {'Classic palettes', 'From photographs', 'Colour combos', 'Community'}


def selectors(css):
    """Top-level and @media/@supports rule selectors."""
    css = re.sub(r'/\*.*?\*/', '', css, flags=re.S)
    out, depth, start, i = [], 0, 0, 0
    stack = []
    while i < len(css):
        c = css[i]
        if c in '"\'':
            i = css.index(c, i + 1) + 1
            continue
        if c == '{':
            prelude = css[start:i].strip()
            stack.append(prelude)
            if not prelude.startswith('@') and not any(p.startswith('@font-face') or p.startswith('@keyframes') for p in stack[:-1]):
                out.extend(s.strip() for s in prelude.split(','))
            start = i + 1
        elif c == '}':
            stack.pop()
            start = i + 1
        elif c == ';':
            start = i + 1
        i += 1
    return out


def check_theme(tid, errors):
    d = os.path.join(ROOT, 'themes', tid)
    err = lambda m: errors.append(f'{tid}: {m}')  # noqa: E731
    if not ID.match(tid):
        err('folder name must be lowercase letters, digits and dashes')
    if tid in BUILTIN:
        err('this id belongs to a built-in Cord theme')
    css_path, json_path = os.path.join(d, 'theme.css'), os.path.join(d, 'theme.json')
    if not os.path.isfile(css_path) or not os.path.isfile(json_path):
        err('needs both theme.css and theme.json')
        return
    css = open(css_path, encoding='utf-8').read()
    if len(css.encode()) > 1024 * 1024:
        err('theme.css is larger than 1 MB')

    for name in re.findall(r'@([a-z-]+)', re.sub(r'/\*.*?\*/', '', css, flags=re.S)):
        if name not in ALLOWED_AT:
            err(f'@{name} is not allowed (Cord drops it)')
    for ref in re.findall(r'url\(\s*["\']?([^"\')]+)', css):
        if re.match(r'^[a-z][a-z0-9+.-]*:|^/', ref.strip(), re.I) and not ref.startswith('data:'):
            err(f'url({ref}) must point at a file beside theme.css')
    scope = f'[data-theme="{tid}"]'
    for sel in selectors(css):
        if sel and not sel.startswith(scope) and not re.match(r'^(from|to|\d+%)$', sel):
            err(f'selector "{sel}" must start with {scope}')

    blocks = parse_blocks(css)
    missing = [t for t in TOKENS if t not in blocks['dark']]
    if missing:
        err('missing colour tokens: ' + ', '.join('--' + t for t in missing))
    else:
        for scheme in ('dark', 'light'):
            p = blocks[scheme]
            if not all(HEX.match(p[k].lower()) for k in ('bg', 'text-primary', 'text-secondary', 'text-muted', 'link-color', 'accent', 'accent-fg')):
                continue  # non-hex values (var(), rgb()) can't be checked here
            for token, target in CONTRAST.items():
                ratio = contrast(p[token], p['bg'])
                if ratio < target:
                    err(f'{scheme}: --{token} on --bg is {ratio:.2f}:1, needs {target}:1')
            ratio = contrast(p['accent-fg'], p['accent'])
            if ratio < 3:
                err(f'{scheme}: --accent-fg on --accent is {ratio:.2f}:1, needs 3:1')

    try:
        meta = json.load(open(json_path, encoding='utf-8'))
    except json.JSONDecodeError as e:
        err(f'theme.json is not valid JSON: {e}')
        return
    for key in ('name', 'description', 'author'):
        if not isinstance(meta.get(key), str) or not meta[key].strip():
            err(f'theme.json needs a "{key}"')
    if len(meta.get('name', '')) > 60:
        err('name is longer than 60 characters')
    if len(meta.get('description', '')) > 140:
        err('description is longer than 140 characters')
    tags = meta.get('tags')
    if not isinstance(tags, list) or not tags or not all(isinstance(t, str) and ID.match(t) for t in tags):
        err('theme.json needs "tags": a list of lowercase words')
    pal = meta.get('palette', {})
    sw = pal.get('swatches') if isinstance(pal, dict) else None
    if not isinstance(sw, list) or not 2 <= len(sw) <= 8 or not all(isinstance(c, str) and HEX.match(c) for c in sw):
        err('theme.json needs "palette": {"credit": ..., "swatches": [2 to 8 "#rrggbb" colours]}')
    if not isinstance(pal, dict) or not pal.get('credit'):
        err('theme.json "palette" needs a "credit" saying where the colours come from')
    if meta.get('group', 'Community') not in GROUPS:
        err('"group" must be one of: ' + ', '.join(sorted(GROUPS)))


def main():
    themes = sorted(n for n in os.listdir(os.path.join(ROOT, 'themes')) if os.path.isdir(os.path.join(ROOT, 'themes', n)))
    errors = []
    for tid in themes:
        check_theme(tid, errors)
    stray = [n for n in os.listdir(ROOT) if n.endswith('.css')]
    if stray:
        errors.append('loose .css files at the top level: ' + ', '.join(stray) + ' (put themes in themes/<id>/)')
    if errors:
        print('\n'.join(errors))
        print(f'\n{len(errors)} problem(s) in {len(themes)} themes')
        sys.exit(1)
    print(f'{len(themes)} themes ok')


if __name__ == '__main__':
    main()
