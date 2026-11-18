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
    tail: ['#FFE84E', '#FFB83A', '#FF7A35', '#FF3D5E', '#FF4656'],
    flame: 'rgba(255, 238, 120, 0.45)',
    ember: 'rgba(255, 112, 40, 0.35)',
    body: ['#FF4060', '#FF5A32', '#FF8A2E'],
    belly: 'rgba(255, 170, 70, 0.6)',
    cheek: ['#FFC23C', '#FFDC4E'],
    ear: '#E9452F',
    nearEar: '#FF7A2E',
    leg: ['#F2306B', '#D81B66'],
    farLeg: ['#C81F5E', '#A0104C'],
    eye: '#1D1133',
  };

  // Kit's paths are traced from the designer's 1920 × 1080 running frame,
  // where the feet stand on (KIT_X, KIT_Y), and drawn at KIT_SCALE.
  const KIT_X = 1230;
  const KIT_Y = 935;
  const KIT_SCALE = 0.11;

  // Facing right with the feet on (x, y), roughly 140 × 65 units at s = 1
  // including the tail. `phase` drives the gallop, pose is 'run', 'jump' or
  // 'hurt', and `tilt` leans the body nose-up by that many radians.
  function fox(ctx, x, y, s, phase, pose, tilt = 0) {
    ctx.save();
    ctx.translate(x, y);
    ctx.scale(s * KIT_SCALE, s * KIT_SCALE);
    ctx.translate(-KIT_X, -KIT_Y);

    const running = pose === 'run';
    const spread = running ? Math.cos(phase) : 1;
    const gather = (1 - spread) / 2;
    const bob = running ? -Math.max(0, spread) * 18 : 0;
    ctx.translate(1280, 735 + bob);
    ctx.rotate(-tilt);
    ctx.translate(-1280, -735);

    const legs = kitLegs(phase, pose);
    const hind = [1080 + 25 * gather, 800];
    const front = [1400 - 12 * gather, 815];

    kitLeg(ctx, [front[0] + 10, front[1] - 6], legs.farFront, false, KIT.farLeg, KIT.farLeg[0]);
    kitLeg(ctx, [hind[0] + 20, hind[1] + 4], legs.farHind, true, KIT.farLeg, KIT.farLeg[0]);

    const tailBase = { x: 1100 + 25 * gather, y: 760 };
    if (running) kitTail(ctx, tailBase, 0.06 * Math.cos(phase - 0.6), phase, 0.12);
    else if (pose === 'jump') kitTail(ctx, tailBase, -0.08 - 0.5 * tilt, 1.2, 0.06);
    else kitTail(ctx, tailBase, -0.25, 0.4, 0.08);

    kitEar(ctx, [1428, 690], [1433, 646], [1490, 696], KIT.ear);
    kitEar(ctx, [1398, 708], [1406, 648], [1448, 688], KIT.nearEar);
    kitBody(ctx, gather);
    kitLeg(ctx, hind, legs.hind, true, KIT.leg, KIT.body[0]);
    kitLeg(ctx, front, legs.front, false, KIT.leg, '#FF5A3C');
    kitFace(ctx, pose === 'hurt');

    ctx.restore();
  }

  // Each leg is [thigh angle, knee bend]. A positive thigh angle swings the
  // foot forward; the bend folds the lower leg back.
  function kitLegs(phase, pose) {
    if (pose === 'jump') {
      return { hind: [-0.8, 0.2], farHind: [-0.6, 0.3], front: [1.0, 0.25], farFront: [0.8, 0.4] };
    }
    if (pose === 'hurt') {
      return { hind: [0.7, 0.9], farHind: [0.4, 1.1], front: [1.1, 0.5], farFront: [0.8, 0.8] };
    }
    const hind = (offset) => {
      const p = phase + offset;
      return [0.15 - 0.75 * Math.cos(p), 0.3 + 0.9 * Math.max(0, Math.sin(p)) + 0.8 * Math.max(0, -Math.sin(p))];
    };
    const front = (offset) => {
      const p = phase + offset;
      return [0.2 + 0.8 * Math.cos(p), 0.15 + 1.1 * Math.max(0, -Math.sin(p))];
    };
    return { hind: hind(0), farHind: hind(0.5), front: front(0.2), farFront: front(0.7) };
  }

  function kitLeg(ctx, hip, [a, bend], isHind, colors, top) {
    const [upper, lower, thigh, knee, paw] = isHind ? [74, 78, 44, 22, 22] : [62, 62, 28, 22, 22];
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
    limb(ctx, hx, hy, thigh, kx, ky, knee);
    limb(ctx, kx, ky, knee, px, py, paw);
    limb(ctx, px, py, paw, px + Math.sin(toe) * 20, py + Math.cos(toe) * 20, paw + 2);
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

  const S = true;
  const TAIL = [
    [1130, 738], [1050, 694], [940, 652], [840, 600], [780, 530], [690, 428], [590, 356], [490, 338],
    [380, 356], [280, 410, S], [360, 440], [425, 494, S], [355, 528, S], [440, 545], [500, 585],
    [514, 610, S], [490, 625, S], [550, 650], [640, 720], [730, 772], [840, 804], [960, 794],
    [1070, 778], [1115, 795],
  ];
  const TAIL_STREAKS = [
    [KIT.flame, [[450, 382], [540, 418], [605, 482], [645, 565, S], [592, 505], [530, 442]]],
    [KIT.flame, [[495, 518], [565, 522], [615, 562, S], [560, 540]]],
    [KIT.ember, [[520, 556], [600, 580], [655, 632, S], [592, 598]]],
    [KIT.ember, [[600, 556], [655, 585], [690, 622, S], [645, 596]]],
  ];
  const TAIL_LENGTH = 830;

  // The tail grows from `base` backwards and up. It bends up by `lift`
  // radians at the tip, and a ripple of strength `ripple` runs down it as
  // `wave` advances.
  function kitTail(ctx, base, lift, wave, ripple) {
    const shift = base.x - 1100;
    const bend = ([px, py, sharp]) => {
      const dx = px + shift - base.x;
      const dy = py - base.y;
      const u = Math.min(1, Math.hypot(dx, dy) / TAIL_LENGTH);
      const a = lift * u + ripple * u * Math.sin(wave - 2.6 * u);
      const cos = Math.cos(a);
      const sin = Math.sin(a);
      return { x: base.x + dx * cos - dy * sin, y: base.y + dx * sin + dy * cos, sharp };
    };
    const tail = smoothPath(TAIL.map(bend));
    const tip = bend(TAIL[9]);

    const fill = ctx.createLinearGradient(tip.x + 50, tip.y - 30, base.x - 50, base.y + 20);
    KIT.tail.forEach((color, i) => fill.addColorStop([0, 0.35, 0.62, 0.85, 1][i], color));
    ctx.fillStyle = fill;
    ctx.fill(tail);

    ctx.save();
    ctx.clip(tail);
    for (const [color, points] of TAIL_STREAKS) {
      ctx.fillStyle = color;
      ctx.fill(smoothPath(points.map(bend)));
    }
    ctx.restore();
  }

  // The body and cheek gradients never move in Kit's own coordinates, so
  // each canvas builds them once.
  const kitGradientCache = new WeakMap();

  function kitGradients(ctx) {
    let cached = kitGradientCache.get(ctx);
    if (!cached) {
      const body = ctx.createLinearGradient(1090, 0, 1520, 0);
      KIT.body.forEach((color, i) => body.addColorStop([0, 0.6, 1][i], color));
      const cheek = ctx.createLinearGradient(1400, 0, 1550, 0);
      cheek.addColorStop(0, KIT.cheek[0]);
      cheek.addColorStop(1, KIT.cheek[1]);
      cached = { body, cheek };
      kitGradientCache.set(ctx, cached);
    }
    return cached;
  }

  // The body, neck and head as one shape, with the rump pulled forward by
  // `gather` as the legs bunch up.
  function kitBody(ctx, gather) {
    const rx = 25 * gather;
    const body = new Path2D();
    body.moveTo(1092 + rx, 800);
    body.bezierCurveTo(1074 + rx, 780, 1084 + rx, 736, 1106 + rx, 728);
    body.bezierCurveTo(1170, 714 - 8 * gather, 1280, 724, 1340, 726);
    body.bezierCurveTo(1370, 722, 1395, 708, 1410, 696);
    body.bezierCurveTo(1440, 682, 1480, 684, 1505, 704);
    body.bezierCurveTo(1520, 716, 1538, 724, 1548, 728);
    body.quadraticCurveTo(1558, 738, 1544, 743);
    body.bezierCurveTo(1520, 748, 1482, 752, 1456, 762);
    body.bezierCurveTo(1436, 772, 1420, 784, 1414, 797);
    body.bezierCurveTo(1414, 806, 1410, 818, 1398, 827);
    body.bezierCurveTo(1388, 833, 1372, 833, 1357, 832);
    body.bezierCurveTo(1300, 826, 1200, 816, 1150, 826);
    body.bezierCurveTo(1122 + rx, 832, 1102 + rx, 820, 1092 + rx, 800);
    body.closePath();

    const { body: bodyFill, cheek } = kitGradients(ctx);
    ctx.fillStyle = bodyFill;
    ctx.fill(body);

    ctx.save();
    ctx.clip(body);
    ctx.fillStyle = KIT.belly;
    ctx.beginPath();
    ctx.ellipse(1255, 828, 125, 11, 0.03, 0, TAU);
    ctx.fill();

    ctx.fillStyle = cheek;
    ctx.beginPath();
    ctx.moveTo(1560, 731);
    ctx.bezierCurveTo(1530, 732, 1500, 727, 1470, 724);
    ctx.bezierCurveTo(1445, 721, 1420, 716, 1404, 718);
    ctx.quadraticCurveTo(1394, 722, 1405, 726);
    ctx.quadraticCurveTo(1392, 732, 1402, 737);
    ctx.quadraticCurveTo(1394, 744, 1412, 746);
    ctx.quadraticCurveTo(1416, 756, 1432, 752);
    ctx.bezierCurveTo(1470, 746, 1520, 746, 1560, 744);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
  }

  function kitFace(ctx, hurt) {
    ctx.fillStyle = KIT.eye;
    circle(ctx, 1550, 734, 5.5);
    ctx.fill();
    if (hurt) {
      ctx.strokeStyle = KIT.eye;
      ctx.lineWidth = 5;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';
      ctx.beginPath();
      ctx.moveTo(1482, 702);
      ctx.lineTo(1495, 711);
      ctx.lineTo(1482, 720);
      ctx.stroke();
    } else {
      ctx.beginPath();
      ctx.ellipse(1489, 712, 6.5, 8, 0, 0, TAU);
      ctx.fill();
      ctx.fillStyle = '#FFFFFF';
      circle(ctx, 1491, 709, 2.2);
      ctx.fill();
    }

    if (hooks.foxHead) hooks.foxHead(ctx);
  }

  // An ear from `a` up to `tip` and back down to `b`, with a slightly
  // rounded tip.
  function kitEar(ctx, a, tip, b, color) {
    ctx.beginPath();
    ctx.moveTo(a[0], a[1]);
    ctx.quadraticCurveTo(tip[0] - 6, tip[1] + 14, tip[0], tip[1]);
    ctx.quadraticCurveTo(tip[0] + 18, tip[1] + 8, b[0], b[1]);
    ctx.closePath();
    ctx.fillStyle = color;
    ctx.fill();
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
      const s = Math.min(w / 146, h / 70);
      fox(ctx, w / 2 + 34 * s, h / 2 + 33 * s, s, 0.6, 'run');
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
