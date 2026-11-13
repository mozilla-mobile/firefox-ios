// Fox Dash: an endless runner. Tap to jump over trackers and cookies and grab
// shields for bonus points. The world speeds up the longer you last.
(function () {
  'use strict';

  const { C, TAU, rand, lerp, clamp, fmt, theme } = Arcade;
  const GAME = 'fox-dash';
  // Everything is measured in world units. The screen is at least VIEW_W units
  // wide and MIN_VIEW_H units tall, so landscape sees farther ahead instead of zooming.
  const VIEW_W = 430;
  const MIN_VIEW_H = 520;
  const GRAVITY = 2600;
  const JUMP_V = 760;
  const DOUBLE_JUMP_V = 700;
  const JUMP_BUFFER = 0.12;   // seconds a tap is remembered before landing
  const START_SPEED = 300;
  const MAX_SPEED = 620;
  const RAMP_TIME = 70;       // seconds to cover ~63% of the difficulty curve
  const SHIELD_POINTS = 20;
  const COMBO_STEP = 3;       // shields in a row per multiplier step
  const COMBO_MAX = 3;
  const NEAR_MISS = 8;        // units of clearance that still count as close
  const NEAR_MISS_POINTS = 5;
  const MILESTONE = 5000;     // 500 m, since the score shows distance / 10
  const BOBBER_TIME = 35;     // seconds survived before trackers start bobbing
  const BOB_LOW = 19;
  const BOB_HIGH = 54;
  const HINT_TIME = 2.5;

  // Hitboxes as [x, y, radius] relative to the fox's feet. They skip the
  // tail and legs so near misses feel fair.
  const FOX_HITBOX = [[2, -21, 12], [27, -33, 9]];

  const THEMES = theme.skies;
  const THEME_NAMES = Object.keys(THEMES);
  const ambient = theme.ambient;

  const sfx = {
    jump: () => Arcade.tone({ freq: 320, to: 640, dur: 0.12, vol: 0.07 }),
    doubleJump: () => Arcade.tone({ freq: 480, to: 960, dur: 0.12, vol: 0.07 }),
    shield: (mult) => Arcade.arpeggio([988, 1319].map((f) => f * (1 + 0.12 * (mult - 1))), { step: 0.06, dur: 0.1, type: 'triangle', vol: 0.12 }),
    close: () => Arcade.tone({ freq: 1400, to: 1800, dur: 0.07, type: 'triangle', vol: 0.06 }),
    milestone: () => Arcade.arpeggio([659, 880], { step: 0.07, dur: 0.1, type: 'triangle', vol: 0.06 }),
    crash: () => {
      Arcade.noise({ dur: 0.25, vol: 0.25 });
      Arcade.tone({ freq: 300, to: 60, dur: 0.45, type: 'sawtooth', vol: 0.12 });
    },
    start: () => Arcade.arpeggio([523, 659, 784], { dur: 0.09, vol: 0.06 }),
  };

  const $ = (id) => document.getElementById(id);
  const ui = {
    score: $('score'),
    best: $('best'),
    bestScore: $('best-score'),
    start: $('start'),
    pause: $('pause'),
    over: $('over'),
    overCause: $('over-cause'),
    overScore: $('over-score'),
    overBest: $('over-best'),
    overBestScore: $('over-best-score'),
    overDistance: $('over-distance'),
    overShields: $('over-shields'),
    overCombo: $('over-combo'),
    overClose: $('over-close'),
  };

  const canvas = $('canvas');
  let scale = 1;
  let viewW = VIEW_W;
  let viewH = 800;
  let groundY = 560;
  let foxX = 86;
  let sky = null;
  let skyKey = '';

  const view = Arcade.fitCanvas(canvas, (v) => {
    scale = Math.min(v.width / VIEW_W, v.height / MIN_VIEW_H);
    viewW = v.width / scale;
    viewH = v.height / scale;
    groundY = Math.round(viewH * 0.7);
    foxX = viewW * 0.2;
    sky = null;
  });
  const ctx = view.ctx;
  const fx = Arcade.particles();

  // Small seeded PRNG (mulberry32). Everything that shapes the course draws
  // from it, so each run's seed gives its own course.
  function mulberry32(a) {
    return function () {
      a = (a + 0x6D2B79F5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  // Speed streaks are pure decoration, so they stay on Math.random.
  const streaks = Array.from({ length: 18 }, (_, i) => streak(i % 3 !== 0, Math.random() * viewW));

  function streak(air, x) {
    return { air, x, y: Math.random(), len: rand(30, 90), k: rand(1.3, 2) };
  }

  let state = 'ready'; // ready | playing | paused | dying | over
  let fox, obstacles, shields;
  let speed, time, distance, bonus, shieldCount, spawnIn, deathTimer, cause;
  let seed, rng, look, phase, phaseEnds, phaseRng, patterns, lastClose;
  let combo, bestMult, closeCalls, nextMilestone;
  let scroll = 0;
  let clock = 0;
  let shake = 0;
  let shownScore = -1;

  // Seeded gameplay random in [min, max). Arcade.rand is for cosmetics only.
  const srand = (min, max) => min + rng() * (max - min);

  function reset(runSeed) {
    fox = { h: 0, vy: 0, jumps: 0, buffer: 0, phase: 0 };
    obstacles = [];
    shields = [];
    speed = START_SPEED;
    time = 0;
    distance = 0;
    bonus = 0;
    shieldCount = 0;
    spawnIn = 260;
    shake = 0;
    combo = 0;
    bestMult = 1;
    closeCalls = 0;
    nextMilestone = MILESTONE;
    patterns = 0;
    lastClose = -1;
    fx.clear();

    // Separate streams for the course, the pacing schedule and the look, so
    // one never shifts the others.
    seed = runSeed;
    rng = mulberry32(seed ?? 0);
    phaseRng = mulberry32((seed ?? 0) ^ 0x51ED270B);
    look = seed === undefined ? defaultLook() : makeLook(mulberry32((seed ?? 0) ^ 0x2545F491));
    sky = null;
    phase = 'normal';
    phaseEnds = 14 + 6 * phaseRng();
  }

  function score() {
    return Math.floor(distance / 10) + bonus;
  }

  // ---------------------------------------------------------------- looks --

  function defaultLook() {
    const r = mulberry32(7);
    const attract = THEMES[theme.attract];
    return {
      ...attract,
      hillShapes: [
        { top: 70, amp: 34, freq: 0.008, parallax: 0.12, seed: 1.3 },
        { top: 22, amp: 20, freq: 0.014, parallax: 0.35, seed: 4.1 },
      ],
      bodyX: 0.76, bodyY: 0.24, bodyR: 28,
      starField: starField(r, attract.stars),
    };
  }

  function makeLook(r) {
    const theme = THEMES[THEME_NAMES[Math.floor(r() * THEME_NAMES.length)]];
    const sun = theme.body === 'sun';
    return {
      ...theme,
      hillShapes: [
        { top: 70, amp: 34 * (0.75 + r() * 0.5), freq: 0.008 * (0.8 + r() * 0.4), parallax: 0.12, seed: r() * 20 },
        { top: 22, amp: 20 * (0.75 + r() * 0.5), freq: 0.014 * (0.8 + r() * 0.4), parallax: 0.35, seed: r() * 20 },
      ],
      bodyX: 0.55 + r() * 0.32,
      bodyY: sun ? 0.5 + r() * 0.12 : 0.14 + r() * 0.16,
      bodyR: sun ? 34 + r() * 8 : 22 + r() * 9,
      starField: starField(r, theme.stars),
    };
  }

  function starField(r, count) {
    return Array.from({ length: count }, () => ({
      x: r() * viewW,
      y: r() * 0.6,
      size: 0.8 + r() * 1.2,
      phase: r() * TAU,
    }));
  }

  // ------------------------------------------------------------- spawning --

  function tracker(x, h) {
    return { kind: 'tracker', x, h, baseH: h, r: 18, extra: 0, t: rng() * 10 };
  }

  // A tracker that drifts between the ground and BOB_HIGH over ~2.4 s. It
  // always has to be jumped: even at the top its hitbox (r 14.8) reaches
  // down to the fox's head circle (centre 33, r 9) on the ground, since
  // 54 - 33 = 21 < 23.8. Clearing it at the top needs the feet above ~60,
  // and a single jump stays above 60 for ~0.4 s, while the bobber takes at
  // most 75 units / 426 = 0.18 s to pass the fox at the speed it unlocks.
  function bobber(x) {
    return { kind: 'tracker', x, h: BOB_LOW, baseH: BOB_LOW, r: 18, extra: 0, t: rng() * 10, bob: srand(2.3, 2.9) };
  }

  function shieldArc(x, peak) {
    shields.push(
      { x: x - 45, h: peak - 25, t: 0 },
      { x, h: peak, t: 0.3 },
      { x: x + 45, h: peak - 25, t: 0.6 },
    );
  }

  function shieldRow(x, count, h) {
    for (let i = 0; i < count; i++) shields.push({ x: x + i * 34, h, t: i * 0.3 });
  }

  // Shields along the path of a single jump that peaks over `x`, so one
  // well-timed tap sweeps the whole trail. `half` is the ground covered on
  // the way up; each shield sits ~27 above the feet, between the hitboxes.
  function shieldTrail(x, count) {
    const half = speed * JUMP_V / GRAVITY;
    const peak = JUMP_V * JUMP_V / (2 * GRAVITY);
    for (let i = 0; i < count; i++) {
      const u = 0.8 * ((2 * i) / (count - 1) - 1);
      shields.push({ x: x + u * half, h: peak * (1 - u * u) + 27, t: i * 0.3 });
    }
  }

  function flyer(x) {
    return { kind: 'flyer', x, h: 118, baseH: 118, r: 15, extra: 0, t: rng() * 10 };
  }

  function cookie(x) {
    return { kind: 'cookie', x, h: 17, baseH: 17, r: 17, extra: 110, t: 0, spin: 0 };
  }

  // 0 at the start, easing toward 1. Drives speed, gaps and shield odds.
  function difficulty() {
    return 1 - Math.exp(-time / RAMP_TIME);
  }

  // Adds the next pattern just past the right edge and returns how much room
  // it needs before the following one. Harder patterns unlock with time
  // survived, so a slow first run never meets them. A single jump peaks at
  // ~111 units and stays above 45 for ~0.45 s, which every pattern respects.
  function spawnPattern() {
    const x = viewW + 40;
    if (phase === 'breather') return spawnBreather(x);

    const d = difficulty();
    const shieldOdds = 0.45 - 0.3 * d;
    // A rush skips the plain single tracker and leans on the denser
    // patterns, but only ones already unlocked by time survived.
    const roll = rng() * (phase === 'rush' ? 0.8 : 1);

    if (time > 95 && roll < 0.12) {
      // Duck the drone, then jump the tracker once it has passed overhead.
      const gap = 60 + speed * 0.55;
      obstacles.push(flyer(x), tracker(x + gap, 19));
      return gap + 40;
    }
    if (time > 95 && roll < 0.22) {
      // Tracker straight into a cookie: land, then jump again.
      const gap = 110 + speed * 0.7;
      obstacles.push(tracker(x, 19), cookie(x + gap));
      return gap + 170;
    }
    if (time > 75 && roll < 0.32) {
      // Three wide: ~200 units to clear, fine at the speed this unlocks.
      obstacles.push(tracker(x, 19), tracker(x + 40, 19), tracker(x + 80, 19));
      if (rng() < shieldOdds) shieldArc(x + 40, 135);
      return 120;
    }
    if (time > 55 && roll < 0.45) {
      obstacles.push(flyer(x));
      shieldRow(x - 50, 4, 16);
      return 40;
    }
    if (time > 40 && roll < 0.58) {
      obstacles.push(tracker(x, 19), tracker(x + 40, 19));
      if (rng() < shieldOdds + 0.2) shieldArc(x + 20, 120);
      return 80;
    }
    if (time > 25 && roll < 0.72) {
      // Cookies roll toward you, so they need extra room.
      obstacles.push(cookie(x));
      return 170;
    }
    // Once you've lasted a while, some stacks and single trackers become
    // bobbers instead. Same room as either: see bobber() for why a single
    // jump still clears one, and the stack already needs the feet above ~58.
    const bob = time > BOBBER_TIME && rng() < 0.4;
    if (time > 12 && roll < 0.85) {
      if (bob) obstacles.push(bobber(x));
      else obstacles.push(tracker(x, 19), tracker(x, 52));
      return 40;
    }
    obstacles.push(bob ? bobber(x) : tracker(x, 19));
    if (rng() < shieldOdds) shieldArc(x, 100);
    return 40;
  }

  // Breathers are roomy and generous: either a lone tracker under a trail of
  // shields, or a free row of shields along the ground. Good for combos.
  function spawnBreather(x) {
    if (rng() < 0.6) {
      // Push the tracker right so the start of the trail spawns off-screen.
      const half = speed * JUMP_V / GRAVITY;
      obstacles.push(tracker(x + 0.8 * half, 19));
      shieldTrail(x + 0.8 * half, 5);
      return 1.6 * half + 40;
    }
    shieldRow(x, 5, 16);
    return 5 * 34 + 20;
  }

  // Seconds of running between patterns. Starts roomy and tightens, but the
  // floor (plus the fixed padding) stays above one jump's ~0.59 s airtime.
  // A rush trims gaps to 75% but never below 0.5 s: every pattern leaves at
  // least 40 units after its last obstacle, so with the fixed 30 there are
  // still 70 + 0.5 * 620 = 380 units (0.61 s at top speed) to land in.
  function gapTime() {
    const d = difficulty();
    const gap = srand(0.95 - 0.35 * d, 1.6 - 0.55 * d);
    if (phase === 'rush') return Math.max(0.5, gap * 0.75);
    if (phase === 'breather') return gap * 1.3;
    return gap;
  }

  // Pacing waves on top of the difficulty ramp: a calm start, then rush,
  // breather and a normal stretch on repeat. The schedule has its own random
  // stream and only depends on time, so frame timing can't shift it.
  function nextPhase() {
    if (phase === 'rush') {
      phase = 'breather';
      phaseEnds = time + 4 + 2 * phaseRng();
    } else if (phase === 'breather') {
      phase = 'normal';
      phaseEnds = time + 9 + 7 * phaseRng();
    } else {
      phase = 'rush';
      phaseEnds = time + 6 + 3 * phaseRng();
    }
  }

  // ------------------------------------------------------------- updating --

  function update(dt) {
    time += dt;
    speed = START_SPEED + (MAX_SPEED - START_SPEED) * difficulty();
    const dx = speed * dt;
    distance += dx;
    scroll += dx;

    if (time >= phaseEnds) nextPhase();
    if (distance >= nextMilestone) milestone();

    updateFox(dt);

    spawnIn -= dx;
    if (spawnIn <= 0) {
      const first = obstacles.length;
      spawnIn = spawnPattern() + 30 + speed * gapTime();
      patterns += 1;
      for (let i = first; i < obstacles.length; i++) obstacles[i].group = patterns;
    }

    for (const o of obstacles) {
      const move = dx + o.extra * dt;
      o.t += dt;
      o.x -= move;
      if (o.kind === 'flyer') o.h = o.baseH + Math.sin(o.t * 3) * 6;
      if (o.kind === 'cookie') o.spin -= move / o.r;
      if (o.bob) o.h = BOB_LOW + (BOB_HIGH - BOB_LOW) * (0.5 - 0.5 * Math.cos(o.t * o.bob));
    }
    obstacles = obstacles.filter((o) => o.x > -80);

    for (const sh of shields) {
      sh.t += dt;
      sh.x -= dx;
      if (!sh.taken && touchesFox(sh.x, groundY - sh.h, 13)) collect(sh);
      if (!sh.taken && !sh.missed && sh.x < foxX - 30) missShield(sh);
    }
    shields = shields.filter((sh) => !sh.taken && sh.x > -40);

    for (const s of streaks) {
      s.x -= dx * s.k;
      if (s.x + s.len < 0) Object.assign(s, streak(s.air, viewW + rand(0, 120)));
    }

    const hit = obstacles.find((o) => touchesFox(o.x, groundY - o.h, o.r * 0.82));
    if (hit) {
      die(hit.kind);
      return;
    }
    judgeNearMisses();
  }

  function updateFox(dt) {
    fox.vy -= GRAVITY * dt;
    fox.h += fox.vy * dt;
    if (fox.h <= 0) {
      if (fox.jumps > 0) {
        fx.burst(foxX, groundY, { count: 5, colors: [C.lilac], speed: 70, size: 3, gravity: 0, life: 0.3, vx: -speed * 0.4 });
      }
      fox.h = 0;
      fox.vy = 0;
      fox.jumps = 0;
      if (fox.buffer > 0) jump();
    }
    fox.buffer = Math.max(0, fox.buffer - dt);
    if (fox.h === 0) fox.phase += dt * speed * 0.045;
  }

  // How far apart a circle and the fox's hitbox are (negative = touching).
  function clearance(x, y, r) {
    let best = Infinity;
    for (const [cx, cy, cr] of FOX_HITBOX) {
      const dx = foxX + cx - x;
      const dy = groundY - fox.h + cy - y;
      best = Math.min(best, Math.hypot(dx, dy) - cr - r);
    }
    return best;
  }

  function touchesFox(x, y, r) {
    return clearance(x, y, r) < 0;
  }

  // Tracks how closely each obstacle came while passing the fox and pays a
  // small bonus for skimming one, at most once per pattern.
  function judgeNearMisses() {
    for (const o of obstacles) {
      if (o.judged || o.x > foxX + 90) continue;
      o.close = Math.min(o.close ?? Infinity, clearance(o.x, groundY - o.h, o.r * 0.82));
      if (o.x > foxX - 40) continue;
      o.judged = true;
      if (o.close < NEAR_MISS && o.group !== lastClose) {
        lastClose = o.group;
        closeCalls += 1;
        bonus += NEAR_MISS_POINTS;
        fx.text(foxX + 20, groundY - fox.h - 70, `+${NEAR_MISS_POINTS}`, C.tracker, 18);
        sfx.close();
      }
    }
  }

  function jump() {
    if (state !== 'playing') return;
    if (fox.jumps >= 2) {
      fox.buffer = JUMP_BUFFER;
      return;
    }
    fox.buffer = 0;
    if (fox.jumps === 0) {
      fox.vy = JUMP_V;
      sfx.jump();
      fx.burst(foxX, groundY, { count: 6, colors: [C.lilac], speed: 90, size: 3, gravity: 0, life: 0.35, vx: -speed * 0.5 });
    } else {
      fox.vy = DOUBLE_JUMP_V;
      sfx.doubleJump();
      fx.burst(foxX + 4, groundY - fox.h - 4, { count: 8, colors: [C.snow, C.ember], speed: 120, size: 3, gravity: 0, life: 0.35 });
    }
    fox.jumps += 1;
  }

  // Shields in a row build a multiplier: x1 for the first COMBO_STEP, then
  // x2, then x3. Letting one scroll past resets it.
  function comboMult() {
    return Math.min(COMBO_MAX, 1 + Math.floor((combo - 1) / COMBO_STEP));
  }

  function collect(sh) {
    sh.taken = true;
    combo += 1;
    const mult = comboMult();
    const points = SHIELD_POINTS * mult;
    bestMult = Math.max(bestMult, mult);
    bonus += points;
    shieldCount += 1;
    const y = groundY - sh.h;
    fx.burst(sh.x, y, { count: 10, colors: [C.purple, C.snow], speed: 160, size: 3, gravity: 0, life: 0.4 });
    fx.text(sh.x, y - 16, mult > 1 ? `+${points} x${mult}` : `+${points}`, mult > 1 ? C.gold : C.ember, 20 + 2 * (mult - 1));
    sfx.shield(mult);
  }

  function missShield(sh) {
    sh.missed = true;
    combo = 0;
  }

  function milestone() {
    fx.text(viewW / 2, groundY * 0.5, `${fmt(nextMilestone / 10)} m`, C.snow, 22);
    nextMilestone += MILESTONE;
    sfx.milestone();
  }

  function die(kind) {
    state = 'dying';
    cause = kind;
    deathTimer = 0.9;
    fox.vy = 520;
    fox.jumps = 2;
    fox.buffer = 0;
    shake = 12;
    fx.burst(foxX + 14, groundY - fox.h - 26, { count: 18, colors: [C.fox, C.snow, C.ink], speed: 300 });
    sfx.crash();
  }

  // ------------------------------------------------------------ game flow --

  function start({ seed: runSeed } = {}) {
    reset(Number.isInteger(runSeed) ? runSeed >>> 0 : Math.floor(Math.random() * 2 ** 32));
    state = 'playing';
    Arcade.hide(ui.start);
    Arcade.hide(ui.over);
    sfx.start();
  }

  function gameOver() {
    state = 'over';
    const final = score();
    const { best, isNewBest } = Arcade.reportScore(GAME, final);
    ui.overCause.dataset.icon = cause;
    ui.overScore.textContent = fmt(final);
    ui.overBestScore.textContent = fmt(best);
    ui.overBest.classList.toggle('is-new', isNewBest);
    ui.overDistance.textContent = `${fmt(Math.floor(distance / 10))} m`;
    ui.overShields.textContent = fmt(shieldCount);
    ui.overCombo.textContent = `x${bestMult}`;
    ui.overCombo.hidden = bestMult <= 1;
    ui.overClose.textContent = `+${NEAR_MISS_POINTS} x${closeCalls}`;
    ui.overClose.hidden = closeCalls === 0;
    showBest(best);
    Arcade.show(ui.over);
    Sprites.paintIcons(ui.over);
  }

  function pause() {
    if (state !== 'playing') return;
    state = 'paused';
    Arcade.show(ui.pause);
  }

  function resume() {
    if (state !== 'paused') return;
    state = 'playing';
    Arcade.hide(ui.pause);
  }

  function showBest(best) {
    ui.best.hidden = best <= 0;
    ui.bestScore.textContent = fmt(best);
  }

  // ------------------------------------------------------------ rendering --

  function render() {
    ctx.setTransform(view.dpr * scale, 0, 0, view.dpr * scale, 0, 0);
    if (shake > 0 && !Arcade.reducedMotion) {
      ctx.translate(rand(-0.5, 0.5) * shake, rand(-0.5, 0.5) * shake);
    }

    const fast = state === 'ready' ? 0 : clamp((speed - 380) / (MAX_SPEED - 380), 0, 1) + (phase === 'rush' ? 0.3 : 0);

    drawSky();
    look.hillShapes.forEach((hill, i) => drawHills(look.hills[i], hill));
    if (!Arcade.reducedMotion) drawStreaks(true, fast);
    drawGround();
    drawStreaks(false, fast);

    for (const sh of shields) Sprites.shield(ctx, sh.x, groundY - sh.h, 10, sh.t);
    for (const o of obstacles) {
      const y = groundY - o.h;
      if (o.kind === 'cookie') Sprites.cookie(ctx, o.x, y, o.r, o.spin);
      else if (o.bob) drawBobber(o, y);
      else Sprites.tracker(ctx, o.x, y, o.r, o.t, { prop: o.kind === 'flyer', lookX: -1, lookY: 0.3 });
    }

    const pose = state === 'dying' || state === 'over' ? 'hurt' : fox.h > 0 ? 'jump' : 'run';
    Sprites.fox(ctx, foxX, groundY - fox.h, 1, fox.phase, pose);
    if (ambient) ambient.draw(ctx, { width: viewW, height: viewH, scroll, clock });
    fx.draw(ctx);

    if (state === 'playing' && time < HINT_TIME) drawHint();
  }

  // The sky drifts from the theme toward its `late` colours as the run goes
  // on. The gradient is only rebuilt when the drift visibly changes.
  function drawSky() {
    const drift = state === 'ready' ? 0 : Math.round(difficulty() * 0.7 * 40) / 40;
    const key = `${drift}`;
    if (!sky || key !== skyKey) {
      skyKey = key;
      sky = ctx.createLinearGradient(0, 0, 0, groundY);
      [0, 0.6, 1].forEach((stop, i) => sky.addColorStop(stop, mix(look.sky[i], look.late[i], drift)));
    }
    ctx.fillStyle = sky;
    ctx.fillRect(-20, -20, viewW + 40, groundY + 20);

    ctx.fillStyle = C.snow;
    for (const star of look.starField) {
      ctx.globalAlpha = 0.4 + 0.35 * Math.sin(clock * 2 + star.phase);
      const x = (((star.x - scroll * 0.02) % viewW) + viewW) % viewW;
      ctx.fillRect(x, star.y * groundY, star.size, star.size);
    }
    ctx.globalAlpha = 1;

    if (look.aurora) drawAurora();

    const mx = viewW * look.bodyX;
    const my = groundY * look.bodyY;
    const r = look.bodyR;
    ctx.fillStyle = look.glow;
    ctx.beginPath();
    ctx.arc(mx, my, r * 1.65, 0, TAU);
    ctx.fill();
    if (look.body === 'sun') {
      ctx.beginPath();
      ctx.arc(mx, my, r * 2.4, 0, TAU);
      ctx.fill();
    }
    ctx.fillStyle = look.disc;
    ctx.beginPath();
    ctx.arc(mx, my, r, 0, TAU);
    ctx.fill();
    if (look.spots) {
      ctx.fillStyle = look.spots;
      ctx.beginPath();
      ctx.arc(mx - r * 0.32, my - r * 0.21, r * 0.21, 0, TAU);
      ctx.arc(mx + r * 0.36, my + r * 0.29, r * 0.14, 0, TAU);
      ctx.fill();
    }
  }

  // Two slow translucent ribbons for the aurora sky.
  function drawAurora() {
    const bands = [[C.tracker, 0.2, 0], [C.purple, 0.28, 2.1]];
    for (const [color, at, shift] of bands) {
      ctx.globalAlpha = 0.16;
      ctx.fillStyle = color;
      ctx.beginPath();
      for (let x = -20; x <= viewW + 20; x += 10) {
        const wx = (x + scroll * 0.03) * 0.012 + shift;
        const y = groundY * at + Math.sin(wx + clock * 0.4) * 16 + Math.sin(wx * 2.7) * 6;
        if (x === -20) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      for (let x = viewW + 20; x >= -20; x -= 10) {
        const wx = (x + scroll * 0.03) * 0.012 + shift;
        ctx.lineTo(x, groundY * at + 34 + Math.sin(wx * 1.4 + clock * 0.3) * 10);
      }
      ctx.closePath();
      ctx.fill();
    }
    ctx.globalAlpha = 1;
  }

  function drawHills(color, { top, amp, freq, parallax, seed: phaseShift }) {
    const offset = scroll * parallax;
    const y0 = groundY - top;
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.moveTo(-20, groundY + 1);
    for (let x = -20; x <= viewW + 20; x += 8) {
      const wx = (x + offset) * freq;
      ctx.lineTo(x, y0 - amp * (0.6 * Math.sin(wx + phaseShift) + 0.4 * Math.sin(wx * 2.3 + phaseShift * 1.7)));
    }
    ctx.lineTo(viewW + 20, groundY + 1);
    ctx.closePath();
    ctx.fill();
  }

  function drawGround() {
    ctx.fillStyle = look.ground;
    ctx.fillRect(-20, groundY, viewW + 40, viewH - groundY + 20);
    ctx.fillStyle = look.edge;
    ctx.fillRect(-20, groundY, viewW + 40, 4);

    // Two rows of pebbles at different spacings so the speed reads clearly.
    ctx.fillStyle = look.pebble;
    for (let x = -(scroll % 46); x < viewW + 46; x += 46) ctx.fillRect(x, groundY + 14, 18, 4);
    for (let x = -(scroll % 71); x < viewW + 71; x += 71) ctx.fillRect(x + 23, groundY + 34, 10, 4);
  }

  // Speed lines that fade in as the world speeds up (and during a rush):
  // faint ones in the sky, brighter ones skimming the ground.
  function drawStreaks(air, fast) {
    if (fast <= 0) return;
    ctx.fillStyle = air ? C.lilac : look.edge;
    for (const s of streaks) {
      if (s.air !== air) continue;
      const y = air ? groundY * (0.12 + s.y * 0.8) : groundY + 6 + s.y * 48;
      ctx.globalAlpha = Math.min(1, fast) * (air ? 0.16 : 0.35);
      ctx.fillRect(s.x, y, s.len * (0.5 + 0.5 * Math.min(1, fast)), air ? 1.5 : 2);
    }
    ctx.globalAlpha = 1;
  }

  // A bobbing tracker with a shadow that shrinks as it rises, so its height
  // reads at a glance, and an eye that follows its direction.
  function drawBobber(o, y) {
    const lift = (o.h - BOB_LOW) / (BOB_HIGH - BOB_LOW);
    ctx.fillStyle = 'rgba(18, 10, 34, 0.45)';
    ctx.beginPath();
    ctx.ellipse(o.x, groundY + 3, o.r * (1 - 0.4 * lift), 4 * (1 - 0.4 * lift), 0, 0, TAU);
    ctx.fill();
    const rising = Math.sin(o.t * o.bob) > 0;
    Sprites.tracker(ctx, o.x, y, o.r, o.t, { lookX: -0.8, lookY: rising ? -0.7 : 0.7, sx: rising ? 0.94 : 1.04, sy: rising ? 1.06 : 0.96 });
  }

  function drawHint() {
    const x = viewW / 2;
    const y = groundY + (viewH - groundY) * 0.45;
    const pulse = (clock * 1.5) % 1;
    ctx.globalAlpha = Math.min(1, (HINT_TIME - time) * 2);
    ctx.strokeStyle = C.lilac;
    ctx.fillStyle = C.lilac;
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(x, y, 8, 0, TAU);
    ctx.fill();
    ctx.globalAlpha *= 1 - pulse;
    ctx.beginPath();
    ctx.arc(x, y, 12 + pulse * 22, 0, TAU);
    ctx.stroke();
    ctx.globalAlpha = 1;
  }

  // Blends two #RRGGBB colours.
  function mix(a, b, t) {
    const pa = parseInt(a.slice(1), 16);
    const pb = parseInt(b.slice(1), 16);
    const ch = (shift) => Math.round(lerp((pa >> shift) & 255, (pb >> shift) & 255, t));
    return `rgb(${ch(16)}, ${ch(8)}, ${ch(0)})`;
  }

  function syncHud() {
    const s = score();
    if (s !== shownScore) {
      shownScore = s;
      ui.score.textContent = fmt(s);
    }
  }

  // ---------------------------------------------------------------- input --

  canvas.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    jump();
  });

  window.addEventListener('keydown', (e) => {
    if (e.repeat) return;
    if (state === 'playing' && (e.code === 'Space' || e.code === 'ArrowUp' || e.code === 'KeyW')) {
      e.preventDefault();
      jump();
    } else if (e.code === 'Escape' || e.code === 'KeyP') {
      if (state === 'playing') pause();
      else if (state === 'paused') resume();
    }
  });

  document.addEventListener('visibilitychange', () => {
    if (document.hidden) pause();
  });
  window.addEventListener('blur', pause);

  Arcade.bindPlay([$('play'), $('again')], start);
  $('resume').addEventListener('click', resume);
  $('pause-btn').addEventListener('click', pause);
  Arcade.bindMute($('mute'));
  Arcade.lockGestures();

  // ------------------------------------------------------------------ run --

  reset();
  showBest(Arcade.bestScore(GAME));
  Sprites.paintIcons();

  Arcade.loop((dt) => {
    clock += dt;
    if (state === 'playing') {
      update(dt);
    } else if (state === 'dying') {
      updateFox(dt);
      deathTimer -= dt;
      if (deathTimer <= 0) gameOver();
    } else if (state === 'ready') {
      // Attract mode behind the start screen: the fox jogs along.
      scroll += 120 * dt;
      fox.phase += dt * 6;
    }
    if (state !== 'paused') {
      fx.update(dt);
      shake = Math.max(0, shake - dt * 30);
      if (ambient) ambient.update(dt);
    }
    render();
    syncHud();
  });
})();
