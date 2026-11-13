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

  // Facing right, roughly 110 × 56 units at s = 1. `phase` drives the run
  // cycle; pose is 'run', 'jump' or 'hurt'.
  function fox(ctx, x, y, s, phase, pose) {
    ctx.save();
    ctx.translate(x, y);
    ctx.scale(s, s);

    const running = pose === 'run';
    const bob = running ? -Math.abs(Math.sin(phase)) * 2.5 : 0;
    const fixed = pose === 'jump' ? [1, -1] : pose === 'hurt' ? [0.6, -0.6] : null;
    const angle = (front, offset) => {
      if (fixed) return front ? fixed[0] : fixed[1];
      return running ? Math.sin(phase + offset) * 0.85 : 0;
    };

    leg(ctx, 13, -15 + bob, angle(true, Math.PI), C.foxDark);
    leg(ctx, -12, -15 + bob, angle(false, 0), C.foxDark);

    ctx.save();
    ctx.translate(0, bob);
    foxTail(ctx, running ? Math.sin(phase * 0.5) * 3 : pose === 'jump' ? -5 : 0);
    foxBody(ctx);
    foxHead(ctx, pose === 'hurt');
    ctx.restore();

    leg(ctx, 15, -15 + bob, angle(true, 0), C.fox);
    leg(ctx, -10, -15 + bob, angle(false, Math.PI), C.fox);

    ctx.restore();
  }

  // A positive angle swings the foot forward. The lower half stays ink so
  // the fox gets dark socks.
  function leg(ctx, hx, hy, a, color) {
    const L = 15;
    outline(ctx, 8);
    ctx.beginPath();
    ctx.moveTo(hx, hy);
    ctx.lineTo(hx + Math.sin(a) * L, hy + Math.cos(a) * L);
    ctx.stroke();
    ctx.strokeStyle = color;
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.moveTo(hx, hy);
    ctx.lineTo(hx + Math.sin(a) * L * 0.55, hy + Math.cos(a) * L * 0.55);
    ctx.stroke();
  }

  function foxTail(ctx, wag) {
    const tail = new Path2D();
    tail.moveTo(-15, -27);
    tail.bezierCurveTo(-30, -24, -42, -28 + wag, -54, -43 + wag);
    tail.bezierCurveTo(-43, -49 + wag, -27, -42, -14, -33);
    tail.closePath();
    ctx.fillStyle = C.fox;
    ctx.fill(tail);
    ctx.save();
    ctx.clip(tail);
    ctx.fillStyle = C.snow;
    circle(ctx, -54, -44 + wag, 10);
    ctx.fill();
    ctx.restore();
    outline(ctx, 2.5);
    ctx.stroke(tail);
  }

  function foxBody(ctx) {
    const body = new Path2D();
    body.ellipse(0, -23, 21, 11.5, 0, 0, TAU);
    ctx.fillStyle = C.fox;
    ctx.fill(body);
    ctx.save();
    ctx.clip(body);
    ctx.fillStyle = C.snow;
    ctx.beginPath();
    ctx.ellipse(8, -13, 16, 6.5, 0, 0, TAU);
    ctx.fill();
    ctx.restore();
    outline(ctx, 2.5);
    ctx.stroke(body);
  }

  function foxHead(ctx, hurt) {
    // Ears first, so the head covers their base.
    ear(ctx, [17, -38], [20, -53], [27, -41], C.foxDark);
    ear(ctx, [23, -41], [30, -55], [34, -39], C.fox);

    const head = new Path2D();
    head.moveTo(14, -29);
    head.bezierCurveTo(12, -44, 29, -48, 34, -39);
    head.lineTo(45, -30);
    head.quadraticCurveTo(47, -26, 42, -24.5);
    head.bezierCurveTo(33, -21, 21, -20, 14, -29);
    head.closePath();
    ctx.fillStyle = C.fox;
    ctx.fill(head);
    ctx.save();
    ctx.clip(head);
    ctx.fillStyle = C.snow;
    ctx.beginPath();
    ctx.ellipse(36, -22, 12, 5.5, -0.15, 0, TAU);
    ctx.fill();
    ctx.restore();
    outline(ctx, 2.5);
    ctx.stroke(head);

    ctx.fillStyle = C.ink;
    circle(ctx, 44.5, -28.5, 2.3);
    ctx.fill();

    if (hurt) {
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(28.5, -37.5); ctx.lineTo(32.5, -33.5);
      ctx.moveTo(32.5, -37.5); ctx.lineTo(28.5, -33.5);
      ctx.stroke();
    } else {
      circle(ctx, 30.5, -35.5, 2.4);
      ctx.fill();
      ctx.fillStyle = C.snow;
      circle(ctx, 31.3, -36.3, 0.9);
      ctx.fill();
    }

    if (hooks.foxHead) hooks.foxHead(ctx);
  }

  function ear(ctx, a, tip, b, color) {
    ctx.beginPath();
    ctx.moveTo(a[0], a[1]);
    ctx.lineTo(tip[0], tip[1]);
    ctx.lineTo(b[0], b[1]);
    ctx.closePath();
    ctx.fillStyle = color;
    ctx.fill();
    outline(ctx, 2.5);
    ctx.stroke();
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
      const s = Math.min(w / 112, h / 60);
      fox(ctx, w / 2 + 8 * s, h / 2 + 28 * s, s, 0.6, 'run');
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
