// Harbour: a lighthouse on a rock at night, a black shape against a dithered
// sky with a large dim moon behind it. The lamp turns, so its beam sweeps out
// to one side, fades, and swings out to the other. The sea glitters below.

float scene(vec2 p, vec2 span) {
  float t = uTime;
  float horizon = span.y * 0.74;
  vec2 lamp = vec2(span.x - 0.3, span.y * 0.4);

  // Sky: dark overhead, paler toward the horizon, with slow drifting haze.
  float g = clamp(p.y / horizon, 0.0, 1.0);
  float sky = 0.1 + 0.48 * g * g + (fbm(vec2(p.x * 1.4 + t * 0.01, p.y * 3.0)) - 0.5) * 0.12;

  // A large dim moon low in the sky, a little darker than the haze around it.
  vec2 moon = vec2(span.x - 0.62, span.y * 0.46);
  float md = length(p - moon);
  sky *= mix(0.62, 1.0, smoothstep(0.24, 0.255, md));

  // Beam: a horizontal shaft to one side, then the other, as the lamp turns.
  float turn = t * 0.45;
  float side = cos(turn);
  vec2 d = p - lamp;
  float along = d.x * (side > 0.0 ? -1.0 : 1.0);
  if (along > 0.0) {
    float width = 0.01 + along * 0.025;
    float shaft = 1.0 - smoothstep(width * 0.7, width, abs(d.y));
    float haze = 0.7 + 0.5 * fbm(vec2(p.x * 6.0 - t * 0.05, p.y * 12.0));
    sky += shaft * abs(side) * exp(-along * 1.3) * haze * 0.75;
  }
  // When it faces us the lamp flares.
  sky += max(0.0, sin(turn)) * (1.0 - smoothstep(0.0, 0.07, length(d))) * 0.6;

  // Rocks at the foot of the tower.
  float rocks = horizon - 0.035 - 0.03 * fbm(vec2(p.x * 14.0, 1.0));
  if (abs(p.x - lamp.x) < 0.17 - (horizon - p.y) * 1.2 && p.y > rocks && p.y < horizon + 0.02) return 0.0;

  // Tower: a tapered black shape with two lit windows.
  float top = lamp.y + 0.03;
  float k = clamp((p.y - top) / (horizon - top), 0.0, 1.0);
  float halfW = mix(0.026, 0.045, k);
  if (abs(d.x) < halfW && p.y > top && p.y < horizon) {
    float win = step(abs(d.x), 0.005) * (step(abs(k - 0.35), 0.03) + step(abs(k - 0.65), 0.03));
    return win > 0.0 ? 0.8 : 0.0;
  }
  // Lantern room: bright glass with dark bars, a gallery rail, a dark cap.
  if (abs(d.x) < 0.024 && abs(d.y) < 0.02) return step(0.004, abs(abs(d.x) - 0.011)) > 0.5 ? 1.0 : 0.0;
  if (abs(d.x) < 0.032 && abs(d.y - 0.024) < 0.004) return 0.0;
  if (d.y < -0.02 && d.y > -0.06 && abs(d.x) < 0.028 + (d.y + 0.02) * 0.7) return 0.0;

  if (p.y > horizon) {
    // A dark band of far sea, then water that glitters more toward us.
    if (p.y < horizon + 0.025) return 0.0;
    float near = (p.y - horizon) / (span.y - horizon);
    float ripple = vnoise(vec2(p.x * 14.0 + t * 0.15, p.y * 55.0 - t * 0.6));
    return (0.12 + 0.42 * near) * (0.45 + 0.9 * ripple);
  }
  return sky;
}
