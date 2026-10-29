// Sunset Drive: the sun setting on a dark treeline under a warm sky. Dark
// clouds drift across, their undersides lit where the low sun reaches them.

// Cloud cover at q: 0 clear, 1 thick. Banks are flattened and drift slowly.
float cloud(vec2 p, vec2 span) {
  vec2 q = p * vec2(1.7, 4.5) + vec2(uTime * 0.008, 0.0);
  vec2 warp = vec2(fbm(q * 0.5 + 3.1), fbm(q * 0.5 + 7.3)) - 0.5;
  float n = fbm(q + warp * 1.2);
  // More cloud up high, thinning toward the horizon.
  float height = 1.0 - smoothstep(0.1, 0.65, p.y / span.y);
  return smoothstep(0.5, 0.58, n + height * 0.16 - 0.1);
}

float scene(vec2 p, vec2 span) {
  float horizon = span.y * 0.84;
  vec2 sun = vec2(span.x * 0.66, horizon - 0.04);
  float g = clamp(p.y / horizon, 0.0, 1.0);

  // Treeline: a dark, uneven band along the bottom.
  float trees = horizon - 0.025 * billows(vec2(p.x * 30.0, 1.0)) - 0.012 * fbm(vec2(p.x * 9.0, 2.0));
  if (p.y > trees) return 0.0;

  // The sun: a bright disc with a soft glow spreading along the horizon.
  if (length(p - sun) < 0.045) return 1.0;
  float glow = exp(-length((p - sun) * vec2(0.9, 3.2)) * 3.5);

  // Sky: cool and dim overhead, warm and bright low down.
  float sky = 0.22 + 0.25 * pow(g, 2.0) + 0.3 * glow;
  sky += (fbm(vec2(p.x * 3.0, p.y * 6.0)) - 0.5) * 0.06;

  // Clouds are dark, but their undersides catch the light from below.
  float c = cloud(p, span);
  if (c > 0.0) {
    float below = cloud(p + vec2(0.0, 0.018), span);
    float rim = c * (1.0 - below);
    float dark = 0.04 + 0.1 * g;
    float lit = 0.55 + 0.45 * glow + 0.3 * g;
    return mix(sky, mix(dark, lit, smoothstep(0.1, 0.6, rim)), c);
  }
  return sky;
}
