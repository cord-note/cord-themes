// Winter Woods: a snowy hillside in thick fog. Rows of firs climb the slope
// and fade into the white, a moose stands in the snow, the fog drifts and
// light snow falls.

// The hillside: low on the left, rising to the right.
float slope(float x, vec2 span) {
  return span.y * (0.88 - 0.42 * x / span.x) + 0.012 * sin(x * 9.0);
}

// One row of firs standing along a line `lift` above the slope. Returns 1
// inside a tree. Edges are ragged, like branches seen through fog.
float firs(vec2 p, vec2 span, float lift, float spacing, float tall, float salt) {
  float col = floor(p.x / spacing);
  for (int i = -1; i <= 1; i++) {
    float c = col + float(i);
    if (hash1(vec2(c, salt)) > 0.7) continue;
    float x = (c + 0.2 + 0.6 * hash1(vec2(c, salt + 1.0))) * spacing;
    float foot = slope(x, span) - lift;
    float h = tall * (0.65 + 0.6 * hash1(vec2(c, salt + 2.0)));
    float k = (p.y - (foot - h)) / h;
    if (k < 0.0 || k > 1.05) continue;
    float ragged = 0.6 + 0.8 * vnoise(vec2(p.y * 90.0, c * 7.0 + salt));
    float w = h * 0.16 * k * ragged;
    if (abs(p.x - x) < max(w, k > 0.85 ? 0.004 : 0.0)) return 1.0;
  }
  return 0.0;
}

// A moose, standing side-on and nodding now and then. Returns 1 inside it.
float moose(vec2 p, vec2 at) {
  vec2 q = (p - at) / 0.075;
  float nod = 0.08 * max(0.0, sin(uTime * 0.4)) * max(0.0, sin(uTime * 0.4));
  float body = step(length(q * vec2(0.85, 1.6) - vec2(0.0, -0.75)), 0.55);
  float legs = 0.0;
  for (int i = 0; i < 4; i++) {
    float x = -0.4 + float(i) * 0.27;
    legs = max(legs, step(abs(q.x - x), 0.06) * step(-0.5, q.y) * step(q.y, 0.0));
  }
  float neck = step(abs(q.x - 0.55 - (q.y + 0.9) * 0.4), 0.12) * step(-1.2, q.y) * step(q.y, -0.65);
  float head = step(length((q - vec2(0.82, -1.08 + nod)) * vec2(1.0, 1.6)), 0.2);
  // Antlers: two forked prongs either side of the head.
  vec2 a = q - vec2(0.72, -1.25 + nod);
  float antler = step(abs(a.y + abs(a.x) * 0.4), 0.05) * step(abs(a.x), 0.35);
  antler = max(antler, step(abs(abs(a.x) - 0.3), 0.05) * step(-0.3, a.y) * step(a.y, 0.0));
  return max(max(body, legs), max(max(neck, head), antler));
}

float scene(vec2 p, vec2 span) {
  float t = uTime;
  // Fog: bright and close to even, slowly drifting.
  float fog = 0.72 + 0.12 * (fbm(vec2(p.x * 1.6 - t * 0.012, p.y * 2.5)) - 0.5);

  // Light snow, a little brighter than the fog.
  vec2 s = p + vec2(sin(t * 0.5 + p.y * 3.0) * 0.015, -t * 0.05);
  vec2 id = floor(s / 0.03);
  float flake = step(hash1(id), 0.18) * step(length(fract(s / 0.03) - 0.2 - 0.6 * hash2(id)), 0.12);

  float g = slope(p.x, span);
  if (p.y > g) {
    // Snow, with faint tracks leading up the slope to the moose.
    float track = step(abs(p.y - g - 0.03 - (p.x - span.x * 0.7) * 0.05), 0.003) * step(fract(p.x * 40.0), 0.4) * step(p.x, span.x * 0.7);
    return max(0.86 + 0.06 * fbm(p * 8.0) - track * 0.3, flake);
  }

  // The moose, near the foot of the trees.
  float mx = span.x * 0.72;
  if (moose(p, vec2(mx, slope(mx, span) + 0.005)) > 0.5) return 0.18;

  // Rows of firs: the nearest darkest, each farther row paler in the fog.
  if (firs(p, span, 0.0, 0.05, span.y * 0.2, 3.0) > 0.5) return max(mix(0.32, fog, 0.15), flake);
  if (firs(p, span, 0.06, 0.04, span.y * 0.16, 9.0) > 0.5) return max(mix(0.32, fog, 0.45), flake);
  if (firs(p, span, 0.13, 0.035, span.y * 0.13, 17.0) > 0.5) return max(mix(0.32, fog, 0.7), flake);
  return max(fog, flake * 0.95);
}
