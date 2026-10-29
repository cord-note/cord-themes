// Tokyo Night: a city at night under a deep sky that glows toward the
// horizon. A mountain stands behind, a lattice tower and a slim spire rise
// over the rooftops, windows switch on and off, and a plane crosses slowly
// with its light blinking.

// Lit windows on a facade: brightness, flickering on their own schedule.
float windows(vec2 p, float col, float top, float density, float salt) {
  vec2 cell = vec2(p.x * 160.0, (p.y - top) * 85.0);
  vec2 id = floor(cell) + vec2(col * 13.0, salt);
  vec2 f = fract(cell);
  if (f.x < 0.4 || f.y < 0.45) return 0.0;
  float period = 4.0 + 10.0 * hash1(id);
  float on = step(1.0 - density, hash1(id + floor(uTime / period + hash1(id.yx) * 3.0)));
  return on * (0.7 + 0.3 * hash1(id + 5.0));
}

// One row of buildings: brightness, or -1 where the row has no building.
float row(vec2 p, vec2 span, float base, float rise, float width, float density, float salt) {
  float col = floor(p.x / width);
  float h = hash1(vec2(col, salt));
  float top = span.y * (base - rise * h * h);
  if (p.y < top) return -1.0;
  float x = fract(p.x / width);
  if (x < 0.05) return 0.0;
  // A red light on some rooftops.
  if (p.y < top + 0.006 && abs(x - 0.5) < 0.04 && h > 0.5) return 0.55 + 0.45 * step(0.5, fract(uTime * 0.5 + h));
  return windows(p, col, top, density, salt);
}

// A tower around x: width w(k) where k runs 0 at the tip to 1 at the base.
float towerShape(vec2 p, float x, float tip, float base, float spread, float flare) {
  float k = (p.y - tip) / (base - tip);
  if (k < 0.0 || k > 1.0) return 0.0;
  return step(abs(p.x - x), 0.003 + spread * pow(k, flare));
}

float scene(vec2 p, vec2 span) {
  float t = uTime;
  float g = p.y / span.y;

  // Sky: deep overhead, glowing toward the horizon, a few stars twinkling.
  float sky = 0.05 + 0.55 * pow(clamp(g / 0.78, 0.0, 1.0), 2.4);
  sky += (fbm(vec2(p.x * 2.0, p.y * 3.0 + t * 0.01)) - 0.5) * 0.08;
  vec2 star = floor(p * uUnit);
  if (g < 0.45 && hash1(star) > 0.997) sky = 0.5 + 0.5 * sin(t * 1.5 + hash1(star + 1.0) * 6.28);

  // A plane crossing, with a blinking light.
  vec2 plane = vec2(mod(t * 0.018, span.x + 0.4) - 0.2, span.y * 0.3);
  vec2 q = p - plane;
  float body = step(abs(q.y), 0.004) * step(abs(q.x), 0.03);
  float wing = step(abs(q.x + 0.004 + q.y * 0.6), 0.004) * step(abs(q.y), 0.012);
  float fin = step(abs(q.x + 0.026), 0.004) * step(-0.014, q.y) * step(q.y, 0.0);
  if (max(body, max(wing, fin)) > 0.5) return 0.9;
  if (length(q - vec2(0.032, 0.0)) < 0.004) return step(0.5, fract(t * 0.7)) * 1.0;

  // Lattice tower: lit, flaring at the base, an observation deck, a red tip.
  vec2 a = vec2(span.x * 0.7, 0.0);
  float tipA = span.y * 0.42;
  if (length(p - vec2(a.x, tipA)) < 0.005) return 0.5 + 0.5 * step(0.5, fract(t * 0.6));
  if (towerShape(p, a.x, tipA, span.y * 0.8, 0.05, 2.2) > 0.5) {
    float lattice = step(0.5, fract(p.y * 90.0)) + step(0.6, fract((p.x - a.x) * 120.0 + p.y * 60.0));
    float deck = step(abs(p.y - span.y * 0.58), 0.008);
    return deck > 0.5 ? 1.0 : (lattice > 0.0 ? 0.9 : 0.45);
  }
  // Slim spire: dark, with a lit band and two lit decks.
  float tipB = span.y * 0.26;
  if (towerShape(p, span.x * 0.4, tipB, span.y * 0.8, 0.016, 1.0) > 0.5) {
    float deck = step(abs(p.y - span.y * 0.47), 0.007) + step(abs(p.y - span.y * 0.53), 0.005);
    float band = step(0.3, fract(p.y * 40.0)) * step(span.y * 0.6, p.y);
    return deck > 0.0 ? 0.95 : 0.15 + 0.5 * band;
  }

  // City: a near row of tall blocks in front of a far row.
  float near = row(p, span, 0.86, 0.14, 0.09, 0.4, 3.0);
  if (near >= 0.0) return near;
  float far = row(p, span, 0.8, 0.1, 0.06, 0.3, 11.0);
  if (far >= 0.0) return far * 0.85;

  // Mountain: a broad dark peak behind the city, lit faintly by the glow.
  float m = span.x * 0.55;
  float ridge = span.y * (0.79 - 0.11 * exp(-pow((p.x - m) / 0.2, 2.0)) - 0.03 * fbm(vec2(p.x * 5.0, 0.0)));
  if (p.y > ridge) return 0.3 + 0.08 * fbm(p * 12.0);
  return sky;
}
