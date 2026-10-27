"""Colour helpers shared by the generator, the catalogue and the checker. Standard library only."""
import colorsys
import re

# Every colour token Cord themes set, in the order they are written.
TOKENS = [
    'accent', 'accent-hover', 'accent-fg',
    'bg', 'bg-sidebar', 'bg-panel', 'bg-hover', 'bg-active', 'bg-input', 'bg-elevated',
    'border', 'border-strong', 'border-muted',
    'text-primary', 'text-secondary', 'text-muted',
    'link-color', 'link-underline', 'danger', 'danger-hover-bg', 'danger-border',
    'close-hover-bg', 'close-hover-fg',
]

# Minimum contrast against --bg, per token. WCAG: 4.5 for body text, 3 for large or secondary.
CONTRAST = {'text-primary': 4.5, 'text-secondary': 4.5, 'text-muted': 3.0, 'link-color': 4.5, 'accent': 3.0}


def rgb(h):
    h = h.strip().lstrip('#')
    if len(h) == 3:
        h = ''.join(c * 2 for c in h)
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def hexc(c):
    return '#%02x%02x%02x' % tuple(max(0, min(255, round(v))) for v in c)


def mix(a, b, t):
    """t=0 gives a, t=1 gives b."""
    ra, rb = rgb(a), rgb(b)
    return hexc(tuple(ra[i] + (rb[i] - ra[i]) * t for i in range(3)))


def lum(h):
    def ch(v):
        v /= 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = rgb(h)
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)


def contrast(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def is_dark(h):
    return lum(h) < 0.18


def shift(h, dl):
    """Changes HSL lightness by dl, keeping hue and saturation."""
    r, g, b = (v / 255 for v in rgb(h))
    hh, ll, ss = colorsys.rgb_to_hls(r, g, b)
    ll = max(0.0, min(1.0, ll + dl))
    return hexc(tuple(v * 255 for v in colorsys.hls_to_rgb(hh, ll, ss)))


def fit(colour, bg, target):
    """Moves colour's lightness away from bg until it meets the contrast target, keeping its hue."""
    step = 0.01 if is_dark(bg) else -0.01
    c = colour
    for _ in range(100):
        if contrast(c, bg) >= target:
            return c
        c = shift(c, step)
    # Hue alone could not get there (very saturated mid-tones): blend toward white or black.
    end = '#ffffff' if is_dark(bg) else '#000000'
    for i in range(1, 21):
        c2 = mix(colour, end, i / 20)
        if contrast(c2, bg) >= target:
            return c2
    return end


def rgba(h, a):
    r, g, b = rgb(h)
    return f'rgba({r}, {g}, {b}, {a})'


def parse_blocks(css):
    """Returns {'dark': {token: value}, 'light': {token: value}} from a theme.css."""
    css = re.sub(r'/\*.*?\*/', '', css, flags=re.S)
    out = {'dark': {}, 'light': {}}
    for sel, body in re.findall(r'([^{}]+)\{([^{}]*)\}', css):
        sel = sel.strip()
        if not re.fullmatch(r'\[data-theme="[a-z0-9-]+"\](\[data-scheme="(dark|light)"\])?', sel):
            continue
        scheme = 'light' if 'data-scheme="light"' in sel else 'dark'
        for name, value in re.findall(r'--([a-z0-9-]+)\s*:\s*([^;]+);', body):
            out[scheme][name] = value.strip()
    # A light block inherits anything it leaves out from the dark block.
    out['light'] = {**out['dark'], **out['light']}
    return out
