"""Writes themes/<id>/preview.svg for every theme and regenerates README.md.

Usage:  python tools/catalogue.py           # write
        python tools/catalogue.py --check   # fail if anything is out of date (used by CI)
"""
import json
import os
import sys
from html import escape

sys.path.insert(0, os.path.dirname(__file__))
from colour import parse_blocks  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), '..')
REPO = 'https://github.com/cord-note/cord-themes'
GROUP_ORDER = ['Classic palettes', 'From photographs', 'Colour combos', 'Community']
GROUP_BLURB = {
    'Classic palettes': 'Hand-tuned versions of palettes many people already use in their code editor.',
    'From photographs': 'Palettes pulled from photographs: snow, sea, meadows, ponds and flowers.',
    'Colour combos': 'Simple two-colour combinations that always work, each grown into a full theme.',
    'Community': 'Themes contributed by Cord users.',
}


def window(x, y, p, label):
    """A small Cord window in one scheme, drawn with that scheme's tokens."""
    w, h = 300, 186
    r = []
    a = r.append
    a(f'<g transform="translate({x},{y})">')
    a(f'<rect width="{w}" height="{h}" rx="10" fill="{p["bg"]}" stroke="{p["border-strong"]}"/>')
    # Rail with vault dots.
    a(f'<path d="M10 0h22v{h}h-22a10 10 0 0 1-10-10v-{h - 20}a10 10 0 0 1 10-10z" fill="{p["bg-sidebar"]}"/>')
    a(f'<circle cx="16" cy="22" r="4" fill="{p["accent"]}"/>')
    a(f'<circle cx="16" cy="38" r="3.5" fill="{p["text-muted"]}"/><circle cx="16" cy="53" r="3.5" fill="{p["text-muted"]}"/>')
    # Note list.
    a(f'<rect x="32" width="88" height="{h}" fill="{p["bg-panel"]}"/>')
    a(f'<rect x="120" width="1" height="{h}" fill="{p["border"]}"/>')
    for i, active in enumerate([True, False, False, False]):
        ry = 14 + i * 40
        if active:
            a(f'<rect x="38" y="{ry - 4}" width="76" height="34" rx="5" fill="{p["bg-active"]}"/>')
        a(f'<rect x="44" y="{ry + 2}" width="{56 - i * 6}" height="5" rx="2" fill="{p["text-primary"]}"/>')
        a(f'<rect x="44" y="{ry + 12}" width="40" height="3" rx="1.5" fill="{p["text-muted"]}"/>')
        a(f'<rect x="44" y="{ry + 19}" width="22" height="7" rx="3.5" fill="none" stroke="{p["accent"]}"/>')
    # Editor.
    a(f'<rect x="138" y="20" width="96" height="9" rx="3" fill="{p["text-primary"]}"/>')
    a(f'<rect x="138" y="36" width="34" height="9" rx="4.5" fill="{p["bg-active"]}" stroke="{p["accent"]}"/>')
    lines = [(138, 60, 140, 'text-secondary'), (138, 70, 128, 'text-secondary'), (138, 80, 60, 'link-color'),
             (138, 96, 134, 'text-secondary'), (138, 106, 100, 'text-secondary')]
    for lx, ly, lw, tok in lines:
        a(f'<rect x="{lx}" y="{ly}" width="{lw}" height="4" rx="2" fill="{p[tok]}"/>')
    a(f'<rect x="138" y="120" width="146" height="34" rx="5" fill="{p["bg-input"]}" stroke="{p["border"]}"/>')
    a(f'<rect x="146" y="130" width="70" height="4" rx="2" fill="{p["text-primary"]}"/>')
    a(f'<rect x="146" y="140" width="96" height="4" rx="2" fill="{p["text-muted"]}"/>')
    a(f'<rect x="232" y="162" width="52" height="14" rx="4" fill="{p["accent"]}"/>')
    a(f'<rect x="243" y="167" width="30" height="4" rx="2" fill="{p["accent-fg"]}"/>')
    a(f'<rect x="138" y="167" width="44" height="4" rx="2" fill="{p["danger"]}"/>')
    a('</g>')
    a(f'<text x="{x + w / 2}" y="{y + h + 18}" text-anchor="middle" font-family="system-ui, sans-serif" '
      f'font-size="12" fill="#8a8a8a">{label}</text>')
    return ''.join(r)


def preview(blocks, swatches):
    parts = ['<svg xmlns="http://www.w3.org/2000/svg" width="640" height="262" viewBox="0 0 640 262">',
             window(12, 6, blocks['dark'], 'Dark'), window(328, 6, blocks['light'], 'Light')]
    n = len(swatches)
    sw = (616 - (n - 1) * 6) / n
    for i, c in enumerate(swatches):
        x = 12 + i * (sw + 6)
        parts.append(f'<rect x="{x:.1f}" y="222" width="{sw:.1f}" height="34" rx="6" fill="{c}" stroke="#80808040"/>')
    parts.append('</svg>\n')
    return ''.join(parts)


def load():
    themes = []
    base = os.path.join(ROOT, 'themes')
    for tid in sorted(os.listdir(base)):
        d = os.path.join(base, tid)
        if not os.path.isdir(d):
            continue
        meta = json.load(open(os.path.join(d, 'theme.json'), encoding='utf-8'))
        blocks = parse_blocks(open(os.path.join(d, 'theme.css'), encoding='utf-8').read())
        themes.append((tid, meta, blocks))
    return themes


def readme(themes):
    groups = {g: [] for g in GROUP_ORDER}
    for t in themes:
        groups.setdefault(t[1].get('group', 'Community'), []).append(t)
    tags = sorted({tag for _, m, _ in themes for tag in m.get('tags', [])})

    out = [
        '# Cord Themes', '',
        f'An open, curated list of themes for [Cord](https://github.com/cord-note/cord). '
        f'{len(themes)} themes, each with a dark and a light version that follow your Light, Dark or System setting.', '',
        'New themes are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).', '',
        '## Install', '',
        f'In Cord, open **Settings → Appearance → Theme**, choose **Import → From Git repo…** and paste `{REPO}`. '
        'Every theme appears in the gallery under **Library**.', '',
        'To install only one theme, paste the link to its folder instead, shown under each theme below.', '',
        'You can also download this repository as a zip and use **Import → From zip…**.', '',
        'To update later, right-click a theme in the gallery and choose **Update from source**.', '',
        '## Themes', '',
    ]
    for g in GROUP_ORDER:
        if groups.get(g):
            out.append(f'- [{g}](#{g.lower().replace(" ", "-")}): ' + ', '.join(m['name'] for _, m, _ in groups[g]))
    out += ['', 'Tags: ' + ', '.join(f'`{t}`' for t in tags), '']
    for g in GROUP_ORDER:
        if not groups.get(g):
            continue
        out += [f'## {g}', '', GROUP_BLURB[g], '']
        for tid, m, _ in sorted(groups[g], key=lambda t: t[1]['name'].lower()):
            pal = m.get('palette', {})
            credit = f'[{pal["credit"]}]({pal["url"]})' if pal.get('url') else pal.get('credit', '')
            out += [
                f'### {m["name"]}', '',
                m['description'], '',
                f'![{escape(m["name"])} in dark and light](themes/{tid}/preview.svg)', '',
                f'- Palette: {credit}',
                f'- Tags: ' + ', '.join(f'`{t}`' for t in m.get('tags', [])),
                f'- Install only this one: `{REPO}/tree/main/themes/{tid}`',
                '',
            ]
    out += [
        '## Credits', '',
        'Colour palettes belong to their authors and are credited under each theme. Where a palette '
        'had no colour dark or light enough for a background, a deeper or paler shade of its own '
        'colours is used, and text colours are adjusted until they meet WCAG contrast (4.5:1 for '
        'text and links). The theme files in this repository are MIT licensed.', '',
    ]
    return '\n'.join(out)


def main():
    check = '--check' in sys.argv
    themes = load()
    wanted = {os.path.join(ROOT, 'themes', tid, 'preview.svg'): preview(b, m['palette']['swatches']) for tid, m, b in themes}
    wanted[os.path.join(ROOT, 'README.md')] = readme(themes)
    stale = []
    for path, text in wanted.items():
        current = open(path, encoding='utf-8').read() if os.path.exists(path) else None
        if current != text:
            stale.append(os.path.relpath(path, ROOT))
            if not check:
                with open(path, 'w', encoding='utf-8', newline='\n') as f:
                    f.write(text)
    if check and stale:
        print('Out of date, run python tools/catalogue.py:\n  ' + '\n  '.join(stale))
        sys.exit(1)
    print(f'{"checked" if check else "wrote"} {len(themes)} previews and README.md' + (f' ({len(stale)} changed)' if stale and not check else ''))


if __name__ == '__main__':
    main()
