// Characters for the Firefox Arcade, drawn with canvas paths so there are no
// image files to load. Everything is centred on (x, y) except the fox, which
// stands with its feet on (x, y).
(function () {
  'use strict';

  const { C, TAU, theme } = Arcade;
  const hooks = theme.sprites || {};

  function circle(ctx, x, y, r) {
    ctx.beginPath();
    ctx.arc(x, y, r, 0, TAU);
  }

  function roundRect(ctx, x, y, w, h, r) {
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + w, y, x + w, y + h, r);
    ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r);
    ctx.arcTo(x, y, x + w, y, r);
    ctx.closePath();
  }

  function outline(ctx, width) {
    ctx.lineJoin = 'round';
    ctx.lineCap = 'round';
    ctx.strokeStyle = C.ink;
    ctx.lineWidth = width;
  }

  // ---------------------------------------------------------------- fox --

  // Kit, the Firefox mascot. The colours are fixed so Kit looks the same in
  // every theme.
  const KIT = {
    tail: ['#FFE65C', '#FFB43A', '#FF7838', '#FF3F62'],
    flame: 'rgba(255, 238, 130, 0.5)',
    body: ['#FF4262', '#FF7A30'],
    belly: 'rgba(255, 196, 80, 0.7)',
    head: '#FF8A2E',
    cheek: ['#FFD45A', '#FFB53F'],
    ear: '#E9452F',
    leg: ['#F2306B', '#D81B66'],
    farLeg: ['#C81F5E', '#A0104C'],
    eye: '#1D1133',
  };

  // Facing right with the feet on (x, y), roughly 135 × 75 units at s = 1
  // including the tail. `phase` drives the gallop, pose is 'run', 'jump' or
  // 'hurt', and `tilt` leans the body nose-up by that many radians.
  function fox(ctx, x, y, s, phase, pose, tilt = 0) {
    ctx.save();
    ctx.translate(x, y);
    ctx.scale(s, s);

    const running = pose === 'run';
    const spread = running ? Math.cos(phase) : 1;
    const gather = (1 - spread) / 2;
    const bob = running ? -Math.max(0, spread) * 2 : 0;
    ctx.translate(6, bob - 24);
    ctx.rotate(-tilt);
    ctx.translate(-6, 24);

    const legs = kitLegs(phase, pose);
    const hind = [-20 + 3 * gather, -23];
    const front = [21 - 1.5 * gather, -22];

    kitLeg(ctx, front, legs.farFront, false, KIT.farLeg, KIT.farLeg[0]);
    kitLeg(ctx, hind, legs.farHind, true, KIT.farLeg, KIT.farLeg[0]);

    if (running) kitTail(ctx, -24 + 3 * gather, -27, 0.1 + 0.2 * Math.cos(phase - 0.6), phase, 0.35);
    else if (pose === 'jump') kitTail(ctx, -24, -27, -0.05 - tilt, 1.2, 0.15);
    else kitTail(ctx, -24, -27, -0.3, 0.4, 0.2);

    kitBody(ctx, gather);
    kitLeg(ctx, hind, legs.hind, true, KIT.leg, KIT.body[0]);
    kitLeg(ctx, front, legs.front, false, KIT.leg, '#FF6A3C');
    kitHead(ctx, pose === 'hurt');

    ctx.restore();
  }

  // Each leg is [thigh angle, knee bend]. A positive thigh angle swings the
  // foot forward; the bend folds the lower leg back.
  function kitLegs(phase, pose) {
    if (pose === 'jump') {
      return { hind: [-0.8, 0.2], farHind: [-0.6, 0.3], front: [0.9, 0.25], farFront: [0.7, 0.4] };
    }
    if (pose === 'hurt') {
      return { hind: [0.7, 0.9], farHind: [0.4, 1.1], front: [1.1, 0.5], farFront: [0.8, 0.8] };
    }
    const hind = (offset) => {
      const p = phase + offset;
      return [0.15 - 0.75 * Math.cos(p), 0.3 + 0.9 * Math.max(0, Math.sin(p))];
    };
    const front = (offset) => {
      const p = phase + offset;
      return [0.1 + 0.75 * Math.cos(p), 0.15 + 1.1 * Math.max(0, -Math.sin(p))];
    };
    return { hind: hind(0), farHind: hind(0.5), front: front(0.2), farFront: front(0.7) };
  }

  function kitLeg(ctx, hip, [a, bend], isHind, colors, top) {
    const [upper, lower, thigh] = isHind ? [10.5, 12.5, 9] : [10, 12, 6];
    const [hx, hy] = hip;
    const kx = hx + Math.sin(a) * upper;
    const ky = hy + Math.cos(a) * upper;
    const shin = a - bend;
    const px = kx + Math.sin(shin) * lower;
    const py = ky + Math.cos(shin) * lower;
    const toe = shin + 1.5;

    const fill = ctx.createLinearGradient(hx, hy, px, py);
    fill.addColorStop(0, top);
    fill.addColorStop(0.45, colors[0]);
    fill.addColorStop(1, colors[1]);
    ctx.fillStyle = fill;
    limb(ctx, hx, hy, thigh, kx, ky, 3.8);
    limb(ctx, kx, ky, 3.8, px, py, 3.1);
    limb(ctx, px, py, 3.1, px + Math.sin(toe) * 2.6, py + Math.cos(toe) * 2.6, 3.3);
  }

  // Fills a capsule from (x1, y1) to (x2, y2) that tapers from width w1 to w2.
  function limb(ctx, x1, y1, w1, x2, y2, w2) {
    const a = Math.atan2(y2 - y1, x2 - x1);
    ctx.beginPath();
    ctx.arc(x1, y1, w1 / 2, a + Math.PI / 2, a - Math.PI / 2);
    ctx.arc(x2, y2, w2 / 2, a - Math.PI / 2, a + Math.PI / 2);
    ctx.closePath();
    ctx.fill();
  }

  // The tail grows from (bx, by) backwards and up. `lift` raises it, and a
  // ripple of strength `ripple` runs down it as `wave` advances.
  function kitTail(ctx, bx, by, lift, wave, ripple) {
    const STEPS = 16;
    const LENGTH = 62;
    const spine = [];
    let x = bx;
    let y = by;
    for (let i = 0; i <= STEPS; i++) {
      const u = i / STEPS;
      const a = 0.4 + lift - 0.35 * u + ripple * u * Math.sin(wave - 2.6 * u);
      const dx = -Math.cos(a);
      const dy = -Math.sin(a);
      const w = (4 + 9 * smoothstep(0.1, 0.65, u)) * (1 - 0.9 * smoothstep(0.8, 1, u) ** 2);
      spine.push({ x, y, dx, dy, nx: Math.sin(a), ny: -Math.cos(a), w, u });
      x += dx * LENGTH / STEPS;
      y += dy * LENGTH / STEPS;
    }

    const at = (p, side, back = 0) => ({ x: p.x + p.nx * p.w * side + p.dx * back, y: p.y + p.ny * p.w * side + p.dy * back });
    const end = spine[STEPS];
    const tip = { x: end.x + end.dx * 3, y: end.y + end.dy * 3, sharp: true };

    const top = spine.map((p) => at(p, 1));
    const bottom = [];
    for (const p of spine) {
      bottom.push(at(p, -1));
      if (p.u === 9 / 16 || p.u === 11 / 16 || p.u === 13 / 16) {
        bottom.push({ ...at(p, -1.15, 7), sharp: true });
        bottom.push({ ...at(p, -0.55, 2.5), sharp: true });
      }
    }
    const tail = smoothPath([...top, tip, ...bottom.reverse()]);

    const fill = ctx.createLinearGradient(tip.x, tip.y, bx, by);
    KIT.tail.forEach((color, i) => fill.addColorStop([0, 0.3, 0.62, 1][i], color));
    ctx.fillStyle = fill;
    ctx.fill(tail);

    ctx.save();
    ctx.clip(tail);
    ctx.fillStyle = KIT.flame;
    for (const [from, side] of [[7, 0.35], [9, -0.3]]) {
      const run = spine.slice(from);
      const edge = run.map((p, i) => at(p, side + 0.22 * Math.sin((Math.PI * i) / (run.length - 1))));
      const inner = run.map((p) => at(p, side - 0.05)).reverse();
      ctx.fill(smoothPath([...edge, { ...at(end, side, 6), sharp: true }, ...inner]));
    }
    ctx.restore();
  }

  function kitBody(ctx, gather) {
    const rx = -27 + 3 * gather;
    const body = new Path2D();
    body.moveTo(rx + 2, -18);
    body.bezierCurveTo(rx - 3, -22, rx - 3, -31, rx + 3, -32.5);
    body.bezierCurveTo(-12, -34.5 - 2.5 * gather, 8, -32, 22, -35);
    body.lineTo(31, -29);
    body.bezierCurveTo(30, -23, 27, -18, 21, -16.5);
    body.bezierCurveTo(12, -15, 2, -17.5 + gather, -8, -17);
    body.bezierCurveTo(-15, -16.5, rx + 5, -15.5, rx + 2, -18);
    body.closePath();

    const fill = ctx.createLinearGradient(rx, 0, 28, 0);
    fill.addColorStop(0, KIT.body[0]);
    fill.addColorStop(1, KIT.body[1]);
    ctx.fillStyle = fill;
    ctx.fill(body);

    ctx.save();
    ctx.clip(body);
    ctx.fillStyle = KIT.belly;
    ctx.beginPath();
    ctx.ellipse(10, -15.5, 16, 2.2, -0.06, 0, TAU);
    ctx.fill();
    ctx.restore();
  }

  function kitHead(ctx, hurt) {
    kitEar(ctx, [24, -39], [26.5, -48.5], [30.5, -40], KIT.ear);
    kitEar(ctx, [28, -40.5], [31.5, -49], [35.5, -39.5], KIT.head);
    kitEar(ctx, [30, -41], [31.7, -46.5], [33.8, -40.5], KIT.ear);

    const head = new Path2D();
    head.moveTo(20, -34.5);
    head.bezierCurveTo(22, -41, 28, -43.5, 34, -42);
    head.bezierCurveTo(39, -41, 43, -37.5, 50, -34.6);
    head.quadraticCurveTo(51.6, -33, 49, -32.2);
    head.bezierCurveTo(44, -31, 39, -29.2, 33, -28.4);
    head.bezierCurveTo(28, -27.8, 23, -29, 20, -31.5);
    head.closePath();
    ctx.fillStyle = KIT.head;
    ctx.fill(head);

    ctx.save();
    ctx.clip(head);
    const cheek = ctx.createLinearGradient(30, -35, 48, -29);
    cheek.addColorStop(0, KIT.cheek[0]);
    cheek.addColorStop(1, KIT.cheek[1]);
    ctx.fillStyle = cheek;
    ctx.beginPath();
    ctx.moveTo(52, -33.6);
    ctx.bezierCurveTo(45, -34.2, 39, -34.6, 34, -35.4);
    ctx.lineTo(28.5, -37.5);
    ctx.lineTo(30.5, -34.8);
    ctx.lineTo(25.5, -34.6);
    ctx.lineTo(29.5, -32.6);
    ctx.lineTo(25, -30.2);
    ctx.lineTo(32, -26);
    ctx.lineTo(52, -26);
    ctx.closePath();
    ctx.fill();
    ctx.restore();

    ctx.fillStyle = KIT.eye;
    circle(ctx, 50.2, -33.7, 1.15);
    ctx.fill();
    if (hurt) {
      ctx.strokeStyle = KIT.eye;
      ctx.lineWidth = 1.5;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';
      ctx.beginPath();
      ctx.moveTo(38.6, -39.4);
      ctx.lineTo(42.2, -37.3);
      ctx.lineTo(38.6, -35.2);
      ctx.stroke();
    } else {
      circle(ctx, 40.6, -37.2, 1.4);
      ctx.fill();
      ctx.fillStyle = '#FFFFFF';
      circle(ctx, 41.1, -37.7, 0.45);
      ctx.fill();
    }

    if (hooks.foxHead) hooks.foxHead(ctx);
  }

  function kitEar(ctx, a, tip, b, color) {
    ctx.beginPath();
    ctx.moveTo(a[0], a[1]);
    ctx.quadraticCurveTo(tip[0] - 1.5, tip[1] + 2, tip[0], tip[1]);
    ctx.quadraticCurveTo(tip[0] + 2, tip[1] + 3, b[0], b[1]);
    ctx.closePath();
    ctx.fillStyle = color;
    ctx.fill();
  }

  function smoothstep(from, to, v) {
    const t = Math.min(1, Math.max(0, (v - from) / (to - from)));
    return t * t * (3 - 2 * t);
  }

  // A closed path through `points` that rounds every corner except the ones
  // marked `sharp`.
  function smoothPath(points) {
    const path = new Path2D();
    path.moveTo(points[0].x, points[0].y);
    for (let i = 1; i < points.length - 1; i++) {
      const p = points[i];
      const next = points[i + 1];
      if (p.sharp) path.lineTo(p.x, p.y);
      else path.quadraticCurveTo(p.x, p.y, (p.x + next.x) / 2, (p.y + next.y) / 2);
    }
    const last = points[points.length - 1];
    path.lineTo(last.x, last.y);
    path.closePath();
    return path;
  }

  // ------------------------------------------------------------ tracker --

  // A one-eyed blob with an antenna. Options: prop (a drone rotor
  // instead of an antenna), lookX/lookY (-1..1),
  // noBlink, sx/sy (squash).
  function tracker(ctx, x, y, r, t, o = {}) {
    ctx.save();
    ctx.translate(x, y);
    ctx.scale(o.sx || 1, o.sy || 1);
    const lw = Math.max(1.5, r * 0.1);
    outline(ctx, lw);

    if (o.prop) {
      ctx.beginPath();
      ctx.moveTo(0, -r * 0.95);
      ctx.lineTo(0, -r * 1.3);
      ctx.stroke();
      const spin = Math.abs(Math.sin(t * 30));
      ctx.fillStyle = C.lilac;
      ctx.beginPath();
      ctx.ellipse(0, -r * 1.35, r * (0.1 + 0.9 * spin), r * 0.14, 0, 0, TAU);
      ctx.fill();
      ctx.stroke();
    } else {
      ctx.beginPath();
      ctx.moveTo(0, -r * 0.95);
      ctx.quadraticCurveTo(r * 0.25, -r * 1.2, r * 0.12, -r * 1.42);
      ctx.stroke();
      ctx.fillStyle = Math.sin(t * 6) > 0 ? C.pink : '#8C2A3E';
      circle(ctx, r * 0.12, -r * 1.5, r * 0.15);
      ctx.fill();
      ctx.stroke();
    }

    // Dome with a wobbly skirt.
    ctx.beginPath();
    ctx.arc(0, 0, r, Math.PI, 0);
    ctx.lineTo(r, r * 0.72);
    const bumps = 3;
    const bw = (2 * r) / bumps;
    for (let i = 0; i < bumps; i++) {
      const bx = r - i * bw;
      const wobble = Math.sin(t * 9 + i * 2) * r * 0.08;
      ctx.quadraticCurveTo(bx - bw / 2, r * 1.08 + wobble, bx - bw, r * 0.72);
    }
    ctx.closePath();
    ctx.fillStyle = C.tracker;
    ctx.fill();
    ctx.stroke();

    ctx.strokeStyle = 'rgba(255, 255, 255, 0.55)';
    ctx.lineWidth = lw * 0.8;
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.75, Math.PI * 1.1, Math.PI * 1.35);
    ctx.stroke();
    outline(ctx, lw);

    const ey = -r * 0.08;
    const er = r * 0.46;
    if (!o.noBlink && t % 3.2 > 3.05) {
      ctx.beginPath();
      ctx.moveTo(-er * 0.8, ey);
      ctx.lineTo(er * 0.8, ey);
      ctx.stroke();
    } else {
      ctx.fillStyle = C.snow;
      circle(ctx, 0, ey, er);
      ctx.fill();
      ctx.stroke();
      const lx = (o.lookX ?? Math.sin(t * 1.7)) * er * 0.38;
      const ly = (o.lookY ?? Math.cos(t * 1.3) * 0.5) * er * 0.38;
      ctx.fillStyle = C.pink;
      circle(ctx, lx, ey + ly, er * 0.52);
      ctx.fill();
      ctx.fillStyle = C.ink;
      circle(ctx, lx, ey + ly, er * 0.26);
      ctx.fill();
      ctx.fillStyle = C.snow;
      circle(ctx, lx + er * 0.15, ey + ly - er * 0.15, er * 0.12);
      ctx.fill();
    }

    // Scowling brow.
    ctx.lineWidth = lw * 1.4;
    ctx.beginPath();
    ctx.moveTo(-er * 1.15, ey - er * 1.25);
    ctx.lineTo(0, ey - er * 0.85);
    ctx.lineTo(er * 1.15, ey - er * 1.25);
    ctx.stroke();

    ctx.restore();
  }

  // ------------------------------------------------------------- cookie --

  const CHIPS = [[0.55, 0.9], [0.6, 2.3], [0.15, 3.3], [0.62, 3.9], [0.5, 4.9]];

  // A bitten tracking cookie. It rolls by `spin` radians but its grumpy face
  // stays upright.
  function cookie(ctx, x, y, r, spin) {
    ctx.save();
    ctx.translate(x, y);
    const lw = Math.max(1.5, r * 0.11);
    outline(ctx, lw);

    ctx.save();
    ctx.rotate(spin);
    if (hooks.cookieBody) {
      hooks.cookieBody(ctx, r, lw);
    } else {
      const bite = -0.8;
      const a0 = bite + 0.55;
      ctx.beginPath();
      ctx.arc(0, 0, r, a0, bite - 0.55 + TAU);
      ctx.quadraticCurveTo(Math.cos(bite) * r * 0.45, Math.sin(bite) * r * 0.45, Math.cos(a0) * r, Math.sin(a0) * r);
      ctx.closePath();
      ctx.fillStyle = '#D89A55';
      ctx.fill();
      ctx.stroke();
      ctx.fillStyle = '#5B2F1C';
      for (const [d, a] of CHIPS) {
        circle(ctx, Math.cos(a) * r * d, Math.sin(a) * r * d, r * 0.12);
        ctx.fill();
      }
    }
    ctx.restore();

    const ex = r * 0.32;
    const ey = -r * 0.05;
    const er = r * 0.2;
    for (const side of [-1, 1]) {
      ctx.fillStyle = C.snow;
      circle(ctx, side * ex, ey, er);
      ctx.fill();
      ctx.stroke();
      ctx.fillStyle = C.ink;
      circle(ctx, side * ex - er * 0.35, ey + er * 0.1, er * 0.5);
      ctx.fill();
    }
    ctx.lineWidth = lw * 1.2;
    ctx.beginPath();
    ctx.moveTo(-ex - er, ey - er * 1.6); ctx.lineTo(-ex + er, ey - er);
    ctx.moveTo(ex + er, ey - er * 1.6); ctx.lineTo(ex - er, ey - er);
    ctx.stroke();
    ctx.restore();
  }

  // ------------------------------------------------------------- shield --

  // A spinning privacy shield pickup.
  function shield(ctx, x, y, r, t) {
    ctx.save();
    ctx.translate(x, y);
    ctx.scale(0.55 + 0.45 * Math.abs(Math.cos(t * 2.5)), 1);
    outline(ctx, Math.max(1.5, r * 0.14));
    if (hooks.shieldBody) {
      hooks.shieldBody(ctx, r);
      ctx.restore();
      return;
    }
    ctx.beginPath();
    ctx.moveTo(0, -r);
    ctx.bezierCurveTo(r * 0.5, -r * 0.72, r * 0.9, -r * 0.75, r * 0.9, -r * 0.55);
    ctx.bezierCurveTo(r * 0.9, r * 0.2, r * 0.5, r * 0.75, 0, r);
    ctx.bezierCurveTo(-r * 0.5, r * 0.75, -r * 0.9, r * 0.2, -r * 0.9, -r * 0.55);
    ctx.bezierCurveTo(-r * 0.9, -r * 0.75, -r * 0.5, -r * 0.72, 0, -r);
    ctx.closePath();
    ctx.fillStyle = C.purple;
    ctx.fill();
    ctx.stroke();
    ctx.strokeStyle = C.snow;
    ctx.lineWidth = r * 0.2;
    ctx.beginPath();
    ctx.moveTo(-r * 0.38, -r * 0.02);
    ctx.lineTo(-r * 0.08, r * 0.3);
    ctx.lineTo(r * 0.42, -r * 0.3);
    ctx.stroke();
    ctx.restore();
  }

  // -------------------------------------------------------------- icons --

  const ICONS = {
    fox(ctx, w, h) {
      const s = Math.min(w / 140, h / 72);
      fox(ctx, w / 2 + 18 * s, h / 2 + 35 * s, s, 0.6, 'run');
    },
    tracker(ctx, w, h) {
      tracker(ctx, w / 2, h * 0.56, Math.min(w, h) * 0.3, 0.4, { lookX: 0.6, lookY: 0.2, noBlink: true });
    },
    flyer(ctx, w, h) {
      tracker(ctx, w / 2, h * 0.6, Math.min(w, h) * 0.28, 0.05, { prop: true, lookX: -0.6, lookY: 0.4, noBlink: true });
    },
    cookie(ctx, w, h) {
      cookie(ctx, w / 2, h / 2, Math.min(w, h) * 0.36, 0.3);
    },
    shield(ctx, w, h) {
      shield(ctx, w / 2, h / 2, Math.min(w, h) * 0.36, 0);
    },
  };

  // Paints every <canvas data-icon="name"> on the page at its CSS size.
  function paintIcons(root = document) {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    root.querySelectorAll('canvas[data-icon]').forEach((canvas) => {
      const rect = canvas.getBoundingClientRect();
      const draw = ICONS[canvas.dataset.icon];
      if (!rect.width || !draw) return;
      canvas.width = Math.round(rect.width * dpr);
      canvas.height = Math.round(rect.height * dpr);
      const ctx = canvas.getContext('2d');
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      draw(ctx, rect.width, rect.height);
    });
  }

  window.Sprites = { fox, tracker, cookie, shield, roundRect, paintIcons };
})();
