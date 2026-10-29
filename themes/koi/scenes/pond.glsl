// Koi: looking down into a pond. Two koi circle slowly under the lily pads,
// their tails swaying; sunlight ripples across the water and rings spread
// where something touches the surface.

// A koi swimming round centre c at radius r; speed is in radians a second
// and its sign sets the direction. Returns the fish's brightness, or -1.
float koi(vec2 p, vec2 c, float r, float speed, float phase, float salt) {
  float head = phase + speed * uTime;
  float dir = sign(speed);
  float best = 1e3;
  float along = 0.0;
  for (int i = 0; i < 10; i++) {
    float fi = float(i);
    // Spine points trail behind the head along the circle, swaying more toward the tail.
    float a = head - dir * fi * 0.026 / r;
    vec2 radial = vec2(cos(a), sin(a));
    float sway = sin(uTime * 4.0 - fi * 0.7) * 0.005 * fi / 9.0;
    vec2 at = c + radial * (r + sway);
    // Thick behind the head, tapering to the tail; the last point is the fin.
    float w = fi < 9.0 ? 0.04 * pow(sin(3.14159 * (fi + 1.5) / 11.0), 0.7) : 0.03;
    float d = length(p - at) - w;
    if (d < best) { best = d; along = fi; }
  }
  if (best > 0.0) return -1.0;
  // Patches of bright and mid scales, fixed to the fish as it moves.
  float patch = fbm(vec2(along * 0.8 + salt, (best + 0.03) * 40.0));
  float tail = step(8.5, along);
  return mix(patch > 0.5 ? 0.95 : 0.55, 0.4, tail);
}

float scene(vec2 p, vec2 span) {
  float t = uTime;
  vec2 c = vec2(span.x * 0.62, span.y * 0.52);

  // Lily pads float above everything: round, with a notch and a few veins.
  for (int i = 0; i < 4; i++) {
    float fi = float(i);
    vec2 at = vec2(span.x * (0.35 + 0.6 * hash1(vec2(fi, 1.0))), span.y * (0.15 + 0.75 * hash1(vec2(fi, 2.0))));
    float radius = 0.05 + 0.035 * hash1(vec2(fi, 3.0));
    vec2 d = p - at;
    float ang = atan(d.y, d.x) + fi * 2.1;
    float notch = step(abs(mod(ang, 6.2832) - 0.3), 0.18);
    if (length(d) < radius && notch < 0.5) {
      float vein = step(abs(sin(ang * 4.0)), 0.1);
      float rim = step(radius - 0.006, length(d));
      return max(0.62 - vein * 0.25, rim * 0.85);
    }
  }

  float fish = max(
    koi(p, c, span.y * 0.22, 0.32, 0.0, 3.0),
    koi(p, c + vec2(0.04, -0.02), span.y * 0.31, -0.22, 2.0, 9.0)
  );
  if (fish >= 0.0) return fish;

  // Water: sunlight caustics drifting over a dark pond.
  float n = fbm(p * 4.5 + vec2(t * 0.04, t * 0.03));
  float caustic = pow(1.0 - abs(2.0 * n - 1.0), 6.0);
  float water = 0.04 + 0.3 * caustic;
  // Each fish casts a soft shadow just below it.
  float shade = max(
    koi(p - vec2(0.015, 0.02), c, span.y * 0.22, 0.32, 0.0, 3.0),
    koi(p - vec2(0.015, 0.02), c + vec2(0.04, -0.02), span.y * 0.31, -0.22, 2.0, 9.0)
  );
  if (shade >= 0.0) water *= 0.3;

  // Rings spreading from where something touched the surface.
  for (int i = 0; i < 3; i++) {
    float fi = float(i);
    float cycle = t / 5.0 + fi * 0.37;
    float age = fract(cycle);
    float id = floor(cycle);
    vec2 at = vec2(span.x * (0.3 + 0.65 * hash1(vec2(id, fi))), span.y * (0.1 + 0.8 * hash1(vec2(fi, id))));
    float ring = abs(length(p - at) - age * 0.2);
    water = max(water, (1.0 - smoothstep(0.002, 0.006, ring)) * 0.7 * (1.0 - age));
  }
  return water > 0.12 ? water : -1.0;
}
