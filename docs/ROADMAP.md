# machin-terminal — Roadmap

Ordered by value toward the [north star](VISION.md): be the best possible *host* for
a shell, full-screen TUIs, and **tmux**. Multiplexing is tmux's job (see VISION).

## Done

- **1 — PTY core** (`spike/pty-relay.src`): `forkpty` a real shell and relay I/O.
  Proves PTY + fork/exec + raw fd I/O + poll in pure MFL.
- **2 — windowed terminal**: raylib glyph grid ← VT parser ← non-blocking PTY drain;
  keystrokes encoded back. Printable text, `\r \n \b \t`, wrap, scroll, SGR
  16/256/truecolor, cursor moves, erase.
- **3 — VT100/xterm subset**: alt-screen (`?47/?1047/?1049`), scroll region
  (DECSTBM) + IND/RI/NEL + SU/SD, IL/DL, ICH/DCH/ECH, save/restore cursor
  (DECSC/DECRC, CSI s/u), reverse video (SGR 7/27), cursor visibility (`?25`),
  app-cursor-keys (`?1`), resizable window → `ioctl(TIOCSWINSZ)`/SIGWINCH,
  `TERM=xterm-256color`. **Verified: `vim`, `htop`, alt-screen enter/restore.**
  **tmux verified running** (panes/splits/status bar render).
- **4 — UTF-8 output decoding.** Multi-byte UTF-8 from the PTY is accumulated into a
  single codepoint before `putc`. **Verified: tmux box-drawing borders render.**
- **5 — Font glyph coverage.** `LoadFontEx` bakes ASCII + Latin-1 + general
  punctuation + arrows + box-drawing/blocks/shapes + Braille into the atlas.
- **6 — Mouse reporting.** X10 and SGR (1006) encoding to the PTY: button
  press/release, wheel, drag (button-event 1002 / any-event 1003), and
  shift/alt/ctrl modifiers. *(Click injection not auto-tested here — no xdotool;
  verified against the xterm spec.)*

## Next — daily-driver quality

- **7 — Mouse selection + clipboard.** Drag-to-select on the grid; copy to the X11
  clipboard; paste (with bracketed-paste). Emulator-level — tmux can't do this for
  you. (Also support OSC 52.)
- **8 — Text attributes.** Bold (distinct from bright), underline, italic, dim,
  inverse already done; strike. Needs bold/italic font faces or synthesis.
- **9 — Native scrollback.** Backlog above the viewport with wheel/PageUp.
  *Lower priority:* in a tmux-centric workflow tmux owns scrollback; this mainly
  helps the moments you're outside tmux.
- **10 — Configuration.** Font family/size, color palette, default geometry,
  cursor style — via a simple file or flags.

## Polish / correctness backlog

- Cursor shapes (DECSCUSR) + blink; focus in/out events (`?1004`).
- True Unicode width: wide (CJK/emoji) and zero-width/combining glyphs.
- DEC special-graphics charset (`ESC(0`) mapping (fallback when a TUI isn't UTF-8).
- Bracketed-paste *forwarding* to apps (`?2004`), not just swallowing.
- Performance pass (dirty-region redraw, render-to-texture) if needed at large sizes.

## Explicit non-goals

Native tiling / tabs / splits / sessions (**use tmux**); a plugin/scripting runtime;
being a multiplexer or window manager. See [VISION.md](VISION.md).
