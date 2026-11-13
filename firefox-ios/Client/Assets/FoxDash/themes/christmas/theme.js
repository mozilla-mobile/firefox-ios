(function () {
  'use strict';

  const TAU = Math.PI * 2;
  const flakes = Array.from({ length: 60 }, () => ({ x: Math.random(), y: Math.random(), r: 0.8 + Math.random() * 1.8, v: 0.04 + Math.random() * 0.08, sway: Math.random() * TAU }));

  function fillStroke(ctx, color) {
    ctx.fillStyle = color;
    ctx.fill();
    ctx.stroke();
  }

  FoxDashThemes.register('christmas', {
    palette: { ink: '#0F1F3F', inkDeep: '#08122A', violet: '#1E3A6B', purple: '#3D7BFF', lilac: '#BFE0FF', tracker: '#7DE8C4' },
    attract: 'icy',
    skies: {
      icy: {
        sky: ['#08122A', '#173866', '#3F72A8'], late: ['#050B1C', '#1E3A7A', '#5E8CC4'],
        hills: ['#DCE8F7', '#B9CCE6'], ground: '#EAF2FF', edge: '#FFFFFF', pebble: '#C5D6EE',
        body: 'moon', disc: '#FFF8F1', spots: '#DCE6F7', glow: 'rgba(191, 224, 255, 0.16)', stars: 80,
      },
      frost: {
        sky: ['#0A1630', '#1B2F66', '#5C6FB0'], late: ['#060D20', '#2A2F78', '#8A86C8'],
        hills: ['#D2DFF2', '#AFC3E0'], ground: '#E4EEFB', edge: '#FFFFFF', pebble: '#BFD0EA',
        body: 'moon', disc: '#FFFFFF', spots: '#D5E0F5', glow: 'rgba(255, 255, 255, 0.14)', stars: 100,
      },
    },
    ambient: {
      update(dt) {
        for (const f of flakes) {
          f.y += f.v * dt;
          f.sway += dt;
          if (f.y > 1) { f.y = 0; f.x = Math.random(); }
        }
      },
      draw(ctx, { width, height }) {
        ctx.fillStyle = '#FFFFFF';
        ctx.globalAlpha = 0.85;
        for (const f of flakes) {
          ctx.beginPath();
          ctx.arc(f.x * width + Math.sin(f.sway) * 8, f.y * height, f.r, 0, TAU);
          ctx.fill();
        }
        ctx.globalAlpha = 1;
      },
    },
    sprites: {
      foxHead(ctx) {
        ctx.lineJoin = 'round';
        ctx.lineCap = 'round';
        ctx.strokeStyle = '#0F1F3F';
        ctx.lineWidth = 2.5;
        ctx.beginPath();
        ctx.moveTo(15, -41);
        ctx.bezierCurveTo(16, -58, 8, -63, -3, -54);
        ctx.bezierCurveTo(10, -52, 22, -49, 34, -44);
        ctx.closePath();
        fillStroke(ctx, '#D62839');
        ctx.beginPath();
        ctx.arc(-3, -54, 4.5, 0, TAU);
        fillStroke(ctx, '#FFFFFF');
        ctx.beginPath();
        ctx.moveTo(15, -41);
        ctx.lineTo(34, -44);
        ctx.strokeStyle = '#0F1F3F';
        ctx.lineWidth = 8.5;
        ctx.stroke();
        ctx.strokeStyle = '#FFFFFF';
        ctx.lineWidth = 5;
        ctx.stroke();
      },
      shieldBody(ctx, r) {
        const s = r * 0.85;
        ctx.beginPath();
        ctx.rect(-s, -s * 0.7, s * 2, s * 1.7);
        fillStroke(ctx, '#D62839');
        ctx.beginPath();
        ctx.rect(-s * 0.22, -s * 0.7, s * 0.44, s * 1.7);
        fillStroke(ctx, '#2FBF71');
        ctx.beginPath();
        ctx.rect(-s * 1.1, -s * 1.05, s * 2.2, s * 0.4);
        fillStroke(ctx, '#2FBF71');
        ctx.beginPath();
        ctx.ellipse(-s * 0.4, -s * 1.35, s * 0.4, s * 0.28, -0.4, 0, TAU);
        ctx.ellipse(s * 0.4, -s * 1.35, s * 0.4, s * 0.28, 0.4, 0, TAU);
        fillStroke(ctx, '#2FBF71');
      },
      cookieBody(ctx, r, lw) {
        ctx.beginPath();
        ctx.arc(0, 0, r, 0, TAU);
        fillStroke(ctx, '#B5651D');
        ctx.fillStyle = '#FFFFFF';
        for (let i = 0; i < 10; i++) {
          const a = (i / 10) * TAU;
          ctx.beginPath();
          ctx.arc(Math.cos(a) * r * 0.8, Math.sin(a) * r * 0.8, r * 0.09, 0, TAU);
          ctx.fill();
        }
        ctx.fillStyle = '#D62839';
        for (const dx of [-0.3, 0.3]) {
          ctx.beginPath();
          ctx.arc(dx * r, r * 0.45, r * 0.11, 0, TAU);
          ctx.fill();
        }
        ctx.lineWidth = lw;
      },
    },
  });
})();
