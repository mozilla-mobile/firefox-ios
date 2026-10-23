---
name: accessibility
description: Implement and review accessible iOS UI across Firefox, Focus, and BrowserKit. Use for changes to controls, navigation, text scaling, color, or animation.
---

# iOS accessibility

When implementing or changing UI:

- Give controls VoiceOver labels, values, and traits that describe their purpose and current state.
- Preserve logical focus after navigation or dynamic updates.
- Support Dynamic Type without clipping text or controls, and keep touch targets usable.
- Preserve contrast and respect Reduce Motion when changing color or animation.
