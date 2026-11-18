// Plumbing for Fox Dash: themed palette, canvas sizing, the frame loop,
// synthesized sound effects, particles and the best score persisted by the app.
(function () {
  'use strict';

  const TAU = Math.PI * 2;

  const theme = FoxDashThemes.current();

  const C = Object.assign({
    ink: '#1D1133',
    inkDeep: '#120A22',
    violet: '#3A1F6B',
    purple: '#9059FF',
    fox: '#FF7139',
    ember: '#FFBD4F',
    gold: '#FFD23F',
    pink: '#FF4F5E',
    lilac: '#C9B8FF',
    snow: '#FFF8F1',
    tracker: '#3FE0A8',
  }, theme.palette);

  const FONT = 'ui-rounded, "SF Pro Rounded", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif';

  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const rand = (min, max) => min + Math.random() * (max - min);
  const lerp = (a, b, t) => a + (b - a) * t;
  const clamp = (v, min, max) => Math.min(max, Math.max(min, v));
  const fmt = (n) => n.toLocaleString();

  let best = Number(window.__FOX_DASH_BEST_SCORE__) || 0;

  function bindPlay(buttons, start) {
    buttons.forEach((b) => b.addEventListener('click', () => start({ seed: Math.floor(Math.random() * 2 ** 32) })));
  }

  // Sizes a canvas to its parent at device resolution and calls onResize with
  // the size in CSS pixels whenever the parent changes size.
  function fitCanvas(canvas, onResize) {
    const ctx = canvas.getContext('2d', { alpha: false });
    const view = { ctx, width: 0, height: 0, dpr: 1 };
    const host = canvas.parentElement;

    function resize() {
      const rect = host.getBoundingClientRect();
      if (!rect.width || !rect.height) return;
      view.dpr = Math.min(window.devicePixelRatio || 1, 2);
      view.width = rect.width;
      view.height = rect.height;
      canvas.width = Math.round(rect.width * view.dpr);
      canvas.height = Math.round(rect.height * view.dpr);
      onResize(view);
    }

    new ResizeObserver(resize).observe(host);
    resize();
    return view;
  }

  // Calls step(dt) every animation frame. dt is capped so a slow frame or a
  // backgrounded tab can't make things tunnel through each other.
  function loop(step) {
    let last = performance.now();
    function frame(now) {
      const dt = Math.min((now - last) / 1000, 1 / 20);
      last = now;
      step(dt);
      requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
  }

  // Sound: short synthesized blips, so there are no audio files to load.
  let audio = null;
  let noiseBuffer = null;
  let muted = false;

  // Browsers only allow audio after a user gesture, so (re)start it on input.
  function unlockAudio() {
    if (!audio) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (!AudioCtx) return;
      audio = new AudioCtx();
    }
    if (audio.state === 'suspended') audio.resume();
  }
  window.addEventListener('pointerdown', unlockAudio, true);
  window.addEventListener('keydown', unlockAudio, true);

  function tone({ freq = 440, to = freq, dur = 0.12, type = 'square', vol = 0.1, delay = 0 } = {}) {
    if (muted || !audio) return;
    const t0 = audio.currentTime + delay;
    const osc = audio.createOscillator();
    const gain = audio.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, t0);
    if (to !== freq) osc.frequency.exponentialRampToValueAtTime(to, t0 + dur);
    gain.gain.setValueAtTime(vol, t0);
    gain.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    osc.connect(gain).connect(audio.destination);
    osc.start(t0);
    osc.stop(t0 + dur + 0.02);
  }

  function arpeggio(freqs, { step = 0.08, ...opts } = {}) {
    freqs.forEach((freq, i) => tone({ ...opts, freq, delay: i * step }));
  }

  function noise({ dur = 0.1, vol = 0.2, delay = 0 } = {}) {
    if (muted || !audio) return;
    if (!noiseBuffer) {
      noiseBuffer = audio.createBuffer(1, Math.floor(audio.sampleRate * 0.5), audio.sampleRate);
      const data = noiseBuffer.getChannelData(0);
      for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1;
    }
    const t0 = audio.currentTime + delay;
    const src = audio.createBufferSource();
    const gain = audio.createGain();
    src.buffer = noiseBuffer;
    gain.gain.setValueAtTime(vol, t0);
    gain.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    src.connect(gain).connect(audio.destination);
    src.start(t0);
    src.stop(t0 + dur);
  }

  function bindMute(button) {
    const sync = () => button.setAttribute('aria-pressed', String(muted));
    button.addEventListener('click', () => {
      muted = !muted;
      sync();
    });
    sync();
  }

  function bestScore() {
    return best;
  }

  function reportScore(score) {
    const prev = best;
    if (score > prev) {
      best = score;
      window.webkit?.messageHandlers?.foxDashBestScore?.postMessage(score);
    }
    return { best, isNewBest: prev > 0 && score > prev };
  }

  // Bursts of dots and floating score text, drawn in whatever units the
  // canvas transform is using.
  function particles() {
    const items = [];
    return {
      burst(x, y, { count = 12, colors = [C.snow], speed = 240, size = 4, gravity = 600, life = 0.6, vx = 0 } = {}) {
        for (let i = 0; i < count; i++) {
          const a = Math.random() * TAU;
          const v = speed * (0.4 + Math.random() * 0.6);
          items.push({
            text: null, x, y, life, age: 0, g: gravity,
            vx: vx + Math.cos(a) * v,
            vy: Math.sin(a) * v - speed * 0.3,
            size: size * (0.6 + Math.random() * 0.8),
            color: colors[i % colors.length],
          });
        }
      },
      text(x, y, text, color = C.snow, size = 24) {
        items.push({ text, x, y, vx: 0, vy: -size * 3, g: 0, size, color, life: 0.8, age: 0 });
      },
      update(dt) {
        let kept = 0;
        for (const p of items) {
          p.age += dt;
          if (p.age >= p.life) continue;
          p.vy += p.g * dt;
          p.x += p.vx * dt;
          p.y += p.vy * dt;
          items[kept++] = p;
        }
        items.length = kept;
      },
      draw(ctx) {
        for (const p of items) {
          const k = 1 - p.age / p.life;
          ctx.globalAlpha = Math.min(1, k * 2);
          if (p.text) {
            ctx.font = `900 ${p.size}px ${FONT}`;
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            ctx.lineJoin = 'round';
            ctx.lineWidth = p.size * 0.24;
            ctx.strokeStyle = C.ink;
            ctx.strokeText(p.text, p.x, p.y);
            ctx.fillStyle = p.color;
            ctx.fillText(p.text, p.x, p.y);
          } else {
            ctx.fillStyle = p.color;
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.size * (0.4 + k * 0.6), 0, TAU);
            ctx.fill();
          }
        }
        ctx.globalAlpha = 1;
      },
      clear() {
        items.length = 0;
      },
    };
  }

  // Shows an overlay. Its buttons ignore input for a moment so a frantic tap
  // from the round that just ended doesn't skip straight past it.
  function show(el) {
    el.hidden = false;
    el.inert = true;
    setTimeout(() => {
      el.inert = false;
      const target = el.querySelector('[data-autofocus]');
      if (target) target.focus({ preventScroll: true });
    }, 700);
  }

  function hide(el) {
    el.hidden = true;
  }

  // Stops pinch-zoom, double-tap zoom and the long-press menu from
  // interrupting play.
  function lockGestures() {
    document.addEventListener('gesturestart', (e) => e.preventDefault());
    document.addEventListener('dblclick', (e) => e.preventDefault());
    document.addEventListener('contextmenu', (e) => e.preventDefault());
  }

  window.Arcade = {
    C, FONT, TAU, reducedMotion, theme,
    rand, lerp, clamp, fmt,
    fitCanvas, loop,
    tone, arpeggio, noise, bindMute,
    bestScore, reportScore, bindPlay,
    particles, show, hide, lockGestures,
  };
})();
